#
# testing ruote
#
# Sun Aug 16 14:25:35 JST 2009
#
require 'yajl'
require 'ruote'
require 'ruote/storage/fs_storage'
require 'test/unit'
require 'ruote/participant'
require 'fileutils'
#define ruote extension
class Ruote::ProcessStatus


  def current_work_items
    current_positions=self.position
    items=current_positions.collect { |pos|
      self.stored_workitems.find { |wi|
        #puts "#{wi.fei.sid} <> #{pos[0]}"
        wi.fei.sid==pos[0] }
    }
    return items
  end
end

class ATest < Test::Unit::TestCase

  include FileUtils


  def setup
    rm_rf("deng_storage")
    @dashboard = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::FsStorage.new('deng_storage')))
    puts "setup!!!!"
    puts @dashboard
  end

  #when timeout reached, the current task will be automatically passed
  #more doc please reference http://ruote.rubyforge.org/common_attributes.html#on_cancel

  def test_return_wfid_when_launch_a_process

    pdef = Ruote.process_definition do
      sequence do
        alpha :id => "alpha"
        #alpha :id => "alpha", :timeout => "1s",:on_timeout=>"error" #on_timeout could be "error" or "redo" or "pass"
        bravo :id => "bravo"
      end
    end
    #puts @dashboard
    @dashboard.register_participant(/.+/, Ruote::StorageParticipant)
    wfid = @dashboard.launch(pdef)
    sleep(3)

    #get the process by wfid
    puts @dashboard.process(wfid)
    puts "===wfids==="
    puts @dashboard.process_wfids
    puts "===ids==="
    puts @dashboard.process_ids
  end

  class ReplyParticipant < Ruote::StorageParticipant
    def on_workitem
      puts "on_workitem gets called"
      super
      #proceed workitem
    end

    def on_reply item
      puts "[reply called] item is "+item.inspect
    end
  end


  def test_on_reply_callback

    pdef = Ruote.process_definition do
      cursor do
        sequence do
          alpha :id => "alpha"
          bravo :id => "bravo"
        end
      end
    end
    #puts @dashboard
    @dashboard.register_participant(/.+/, ReplyParticipant)
    wfid = @dashboard.launch(pdef, {:witem_info => "info"})
    sleep(1)

    sp=@dashboard.storage_participant
    @dashboard.process(wfid).current_work_items.each { |wi| sp.proceed wi }
    sleep(0.5)
    puts "===position"
    puts @dashboard.process(wfid).position

  end

  class ConcurentParticipant < Ruote::StorageParticipant
    def on_workitem
      puts "[on_workitem] #{workitem.fields["id"]}"
      workitem.fields["me"]="aaa"
      super
    end

    def on_reply item
      puts "[on_reply]"
    end

    def on_cancel
      puts "[on_cancel]"
      puts workitem.inspect
      puts workitem.params["ref"]+" gets cancelled"
    end

  end

  def process(wfid)
    @dashboard.process(wfid)
  end

  def test_concurrence
    pdef = Ruote.process_definition do
      cursor do
        concurrence :count => 1 do
          alpha :id => "alpha"
          bravo :id => "bravo"
        end
        gamma :id => "gamma"
      end
    end
    #puts @dashboard
    @dashboard.register_participant(/.+/, ConcurentParticipant)
    wfid = @dashboard.launch(pdef, {:witem_info => "info"})
    sleep(1)

    p=@dashboard.process(wfid)
    puts "===workitems==="
    puts p.workitems.inspect

    puts "===workitems found by position==="
    puts p.current_work_items.inspect
    alpha_item=p.current_work_items.find { |wi| wi.params["id"]=="alpha" }
    beta_item=p.current_work_items.find { |wi| wi.params["id"]=="bravo" }
    puts "alpha:"+alpha_item.inspect

    #proceeding alpha
    @dashboard.storage_participant.proceed alpha_item
    @dashboard.storage_participant.all
    puts "proceeding alpha......."
    sleep(1)
    assert_equal(process(wfid).current_work_items[0].params["ref"], "gamma")


  end

  def test_get_running_processes
  puts @dashboard.processes.count
  end

  class AlphaParticipant < Ruote::StorageParticipant

  end

  class TimeoutParticipant <Ruote::StorageParticipant
    def on_workitem
      puts "#{workitem.params["id"]} is working"
      puts workitem.inspect
      super
    end

    def on_cancel
      puts "#{workitem.params["ref"]} got cancelled !!"
    end

  end

  def test_timeout_should_send_reminder_and_pass
    pdef = Ruote.process_definition do

      sequence do

        alpha :id => "alpha", :timers => "1s: reminder, 2s:pass"
        #alpha :id => "alpha", :timeout => "1s",:on_timeout=>"error" #on_timeout could be "error" or "redo" or "pass"
        bravo :id => "bravo"
      end


    end

    @dashboard.register_participant "alpha", TimeoutParticipant
    @dashboard.register_participant "bravo", TimeoutParticipant
    @dashboard.register_participant :reminder do |item|
      puts "reminder handling"
    end
    wfid=@dashboard.launch(pdef)
    sleep(5)
    puts "-------------result-------------"
    #puts @dashboard.process(wfid).position
    puts @dashboard.process(wfid).current_work_items[0].params["ref"]
    assert_equal "bravo", @dashboard.process(wfid).current_work_items[0].params["ref"]


  end

  def test_timeout_should_send_reminder_and_cancel
    pdef = Ruote.process_definition do
      sequence :on_error=>:error_report do
        alpha :id => "alpha", :timers => "1s: reminder, 2s:timeout",:on_timeout=>:error
        bravo :id => "bravo"
      end
    end

    @dashboard.register_participant "alpha", TimeoutParticipant
    @dashboard.register_participant "bravo", TimeoutParticipant
    @dashboard.register_participant :reminder do |item|
      puts "reminder handling"
    end
    @dashboard.register_participant :error_report do |item|
      puts "[reporting error]"
      puts item.timed_out.inspect
      puts item.error.inspect
    end
    wfid=@dashboard.launch(pdef)
    sleep(5)
    puts "-------------result-------------"
    assert @dashboard.process(wfid).position.empty?


  end


  def test_manually_cancel_work
    pdef = Ruote.process_definition do

      sequence :on_cancel=>:cancel_handler do

        alpha :id => "alpha"

        bravo :id => "bravo"
      end


    end

    @dashboard.register_participant "alpha", TimeoutParticipant
    @dashboard.register_participant "bravo", TimeoutParticipant
    @dashboard.register_participant :cancel_handler do |item|
      puts "[cancel_handler]"
      puts item.inspect
    end

    wfid=@dashboard.launch(pdef)
    sleep(1)

    wi=process(wfid).current_work_items[0]
    puts wi.fei

    @dashboard.cancel(wfid,'reason'=>"can not do the job") # cancel the process
    #TODO: where to read the message
    sleep(1.0)
    puts "-------------result-------------"
    puts process(wfid).schedules
    assert @dashboard.process(wfid).position.empty?


  end

  def test_using_flunk_to_stop_process
    pdef = Ruote.process_definition do
      sequence :on_error=>:error_handler do
        alpha :id => "alpha"
        bravo :id => "bravo"
      end
    end

    @dashboard.register_participant "alpha", TimeoutParticipant
    @dashboard.register_participant "bravo", TimeoutParticipant
    @dashboard.register_participant :error_handler do |item|
      puts "[error_handler]"
      puts "class:#{item.error["class"]} message:#{item.error["message"]}"
    end

    wfid=@dashboard.launch(pdef)
    sleep(1)

    wi=process(wfid).current_work_items[0]
    puts wi.fei
    @dashboard.storage_participant.flunk(wi, ArgumentError, 'sorry?')
    sleep(1.0)
    puts "-------------result-------------"

    puts @dashboard.process(wfid).position
    puts @dashboard.process(wfid).workitems

  end

  def test_same_participant_multi_process

    pdef = Ruote.process_definition do
      sequence :on_error=>:error_handler do
        alpha :id => "alpha"
        bravo :id => "bravo"
      end
    end

    pdef2 = Ruote.process_definition do
      sequence :on_error=>:error_handler do
        alpha :id => "alpha2222"
        bravo :id => "bravo2222"
      end
    end

    @dashboard.register_participant "alpha", TimeoutParticipant
    @dashboard.register_participant "bravo", TimeoutParticipant
    @dashboard.register_participant :error_handler do |item|
      puts "[error_handler]"
      puts "class:#{item.error["class"]} message:#{item.error["message"]}"
    end

    #launch process1 and process2
    wfid1=@dashboard.launch(pdef)
    wfid2=@dashboard.launch(pdef2)
    sleep(1)

    puts "[all] for alpha"
    puts @dashboard.storage_participant.by_participant("alpha").inspect

    #finish work for process1
    @dashboard.process(wfid1).current_work_items.each{|wi| @dashboard.storage_participant.proceed(wi)}
    sleep(1)

    puts "[after proceeding all] for alpha"
    puts @dashboard.storage_participant.by_participant("alpha").inspect
  end

  def test_participant_defined_timeout

    pdef = Ruote.process_definition do
      sequence do
        alpha
        bravo
      end
    end

    @dashboard.register_participant :alpha, AlphaParticipant
    sto = @dashboard.register_participant :bravo, Ruote::StorageParticipant

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('dispatched')
    @dashboard.wait_for('dispatched')

    assert_equal 1, sto.size
    assert_equal 'bravo', sto.first.participant_name

    #logger.log.each { |l| p l }
    assert_equal 2, logger.log.select { |e| e['flavour'] == 'timeout' }.size
    assert_equal 0, @dashboard.storage.get_many('schedules').size

    assert_not_nil sto.first.fields['__timed_out__']
  end

  class MyParticipant
    include Ruote::LocalParticipant

    def consume(workitem)
      # do nothing
    end

    def cancel(fei, flavour)
      # do nothing
    end

    def rtimeout
      '1s'
    end

    def do_not_thread
      true
    end
  end

  def test_participant_class_defined_timeout

    pdef = Ruote.define do
      alpha
      echo 'done.'
    end

    @dashboard.register_participant :alpha, MyParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(wfid)

    assert_equal 'done.', @tracer.to_s
    assert_equal 2, logger.log.select { |e| e['flavour'] == 'timeout' }.size
  end

  def test_pdef_overriden_timeout

    # process definition cancels timeout given by participant

    #@dashboard.noisy = true

    pdef = Ruote.define do
      alpha :timeout => ''
      echo 'done.'
    end

    @dashboard.register_participant :alpha, MyParticipant

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for('dispatched')

    assert_equal 0, @dashboard.storage.get_many('schedules').size
    assert_equal '', @tracer.to_s
  end

  class MyOtherParticipant
    include Ruote::LocalParticipant

    def initialize(opts)
      @opts = opts
    end

    def consume(workitem)
      # do nothing
    end

    def cancel(fei, flavour)
      # do nothing
    end

    def rtimeout(workitem)
      @opts['timeout']
    end
  end

  def test_participant_option_defined_timeout

    pdef = Ruote.define do
      alpha
      bravo
      echo 'done.'
    end

    @dashboard.register_participant :alpha, MyOtherParticipant, 'timeout' => '1s'
    @dashboard.register_participant :bravo, MyOtherParticipant

    #noisy

    wfid = @dashboard.launch(pdef)

    @dashboard.wait_for(:bravo)

    assert_equal 0, @dashboard.storage.get_many('schedules').size
    # no timeout for participant :bravo
  end

  class YetAnotherParticipant
    include Ruote::LocalParticipant

    def initialize(opts)
      @opts = opts
    end

    def consume(workitem)
      # do nothing
    end

    def cancel(fei, flavour)
      # do nothing
    end

    def rtimeout(workitem)
      "#{workitem.fields['timeout'] * 2}s"
    end
  end

  def test_participant_rtimeout_workitem

    pdef = Ruote.process_definition do
      alpha
    end

    @dashboard.register_participant :alpha, YetAnotherParticipant

    #noisy

    wfid = @dashboard.launch(pdef, 'timeout' => 60)

    @dashboard.wait_for(:alpha)
    @dashboard.wait_for(1)

    schedules = @dashboard.storage.get_many('schedules')

    assert_equal 1, schedules.size
    assert_equal '120s', schedules.first['original']

    ps = @dashboard.ps(wfid)

    assert_not_nil ps.expressions.last.h.timers
    assert_equal 1, ps.expressions.last.h.timers.size
    assert_equal 'timeout', ps.expressions.last.h.timers.first.last
  end
end


