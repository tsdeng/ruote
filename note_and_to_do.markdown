
Create a definition
-------------------
###Json format:
  $json_def=["define", {"name"=>"car_process", "revision"=>"0.1"}, [["cursor", {}, [["sequence", {}, [["daniel", {"task"=>"clean car"}, []], ["josh", {"task"=>"sell car"}, []]]]]]]]

Expressions in definition
-------------------------
###concurrence
Advance to next step when all the steps in the concurrence block are proceeded
can specify count in the block , following means concurrence will terminate as soon as 1 of the branches replies
  concurrence :count => 1 do
    alpha
    bravo
  end

Start a process by definition
--------------------------------

  Input: definition object
  Output: the processID
  @dashboard = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::FsStorage.new('deng\_storage')))

*the difference between using a storage and using a worker to construct a dashboard object*
1. using storage: the dashboard can manage process(launch and cancel workflows), but *cannot* run any workflows
*TODO*: does it meant process can not advance to next step?

2. using worker instance: can both manage and tun workflows.


Get the engine
--------------
  @dashboard = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::FsStorage.new('deng\_storage')))

Get participant
---------------
      engine.storage_participant
###Get participant by name
      engine.participant("alpha")

Register Participant
--------------------
There parameters: regex, participand class, options. Can also accept a block, then a block participant is created
    @dashboard.register_participant(/.+/,Ruote::StorageParticipant)

*TODO* what is the difference betweetn BlockParticipant, StorageParticipant and LocalParticipant

###Participant and process
Participants gets registered at a per dashboard basis...so all the alpha will be bind to the same class if it gets registered

###Implement a Participant
By including LocalParticipant. This [page](http://ruote.rubyforge.org/implementing_participants.html) includes instructions on creating customized participant
2 ways: inhereit from "StorageParticipant" or include "LocalParticipant"
*TODO* why want to use LocalParticipant?

###Useful Callback method for StorageParticipant

####on\_workitem as pre hook
#####*NOTICE* 
0. on\_workitem accepts 0 parameter
  

1. ***IMPORTANT*** need to call super in on\_workitem method, otherwise you will lose the workitem when calling 

2. consume will not be called for StorageParticipant and its subclass, but on\_workitem works fine, which will remove the workitem from stored\_workitem
  
####on\_reply item
it gets called once the item is proceed by StorageParticipant. proceed can be called like:
  dashboard.storage\_participant.proceed(work\_item)

####cancel(on\_cancel)
on\_reply: we should use this one, for the participant that does not rely immediately, this method gets called when the workitem comes back
*TODO* Is it the same as proceed

###Storage Participant and LocalParticipant
*Storage Participant includes LocalParticipant*



Get Processes
-------------

###Get wfids for processes
Use @dashboard.process\_wfids. This is cheaper than iterate over all processes

###Get all processes in current engine
    @processes = @dashboard.processes(
      :descending => true, :skip => @skip, :limit => @limit)
###Get a single process by providing wfid
    @process=@dashboard.process(wfid)

    Loop through processes
      @processes.each do |process|
        puts process.wfid
        puts process.position

Find the workitem of current position for a process
---------------------------------------------------

###Glitches
1. after a workitem is proceed, need to reload the process from storage, the process object in the memory does not get updated automatically...

Add following extension for easy access of current work item
class Ruote::ProcessStatus

  def current\_work\_items
    current_positions=self.position
    items=current_positions.collect{|pos|
           self.stored_workitems.find{|wi|
             wi.fei.sid==pos[0]}
        }
    return items
  end
end
    #pos[1],pos[2] are name of participant and name of the workitem
    #sid is the identifier to locate the workitem

Get workitems for a particular participant
-----------------------------------------

Proceed the current workitem
----------------------------

###Suggested api: Ruote::StorageParticipant#proceed(wi)
      RuoteKit.engine.storage_participant.proceed(@workitem)

###Exception[concurrence]: proceeding an workitem that is already finished
  concurrence :count => 1 do
    alpha
    bravo
  end

The on\_cancel method gets called once alpha is proceed

###Terminate depending on the status of workitem. [Detail](http://ruote.rubyforge.org/exp/concurrence.html)
    concurrence :over_if => '${f:over}'
      alpha
      bravo
      charly
    end

###Timeout handling
There are two way to specify timeouts, overriding method rtimeout  for LocalParticipant [see](http://ruote.rubyforge.org/implementing_participants.html), or specify it in the expression
      alpha :id => "alpha", :timers => "1s: reminder, 2s:error"

If using error for timers, then need to specify :on\_error for the sequence as *handler*:
      sequence :on_error=>:error_report do

####Get the reason/message for a timeout
https://groups.google.com/forum/?fromgroups#!topic/openwferu-users/z8S2HnDZuv8
*TODO* filed a issue on [github](https://github.com/jmettraux/ruote/issues/50), waiting for response


Cancel the current workitem
---------------------------
*TODO* how to cancel
####Cancel the Workitem
Dashboard#cancel and pass in the workitem, but the next participant will still get the workitem

####Cancel the workflow
Dashboard#cancel and pass in the wfid. Can define :on\_cancel for the sequence as cancel handler:
      sequence :on_cancel=>:cancel_handler do

####[Suggested way]Raise an error and let workflow do handle that
Using flunk method to raise the error(avaliable on the latest version of ruote)
    @dashboard.storage_participant.flunk(wi, ArgumentError, 'sorry?')

In the error handler, use following code to read the error message
    @dashboard.register_participant :error_handler do |item|
      puts "[error_handler]"
      puts "class:#{item.error["class"]} message:#{item.error["message"]}"
    end
