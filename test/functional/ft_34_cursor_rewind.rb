
#
# Testing Ruote (OpenWFEru)
#
# Fri Nov 13 10:30:32 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/hash_participant'

#
# testing forced rewinding
#
class FtCursorRewindTest < Test::Unit::TestCase
  include FunctionalBase

  def test_cursor_forced_back

    pdef = Ruote.process_definition do
      cursor do
        alpha
        bravo
        charly
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    bravo = @engine.register_participant :bravo, Ruote::HashParticipant
    charly = @engine.register_participant :charly, Ruote::HashParticipant

    #noisy

    #
    # reaching initial situation...

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    alpha.reply(alpha.first)
    wait_for(:bravo)

    #
    # rewinding...

    wi = bravo.first
    wi.fields['__command__'] = [ 'back', 2 ]

    @engine.reply(wi)

    #
    # workitem is back to alpha

    wait_for(:alpha)
  end

  def test_cursor_forced_jump

    pdef = Ruote.process_definition do
      cursor do
        alpha
        bravo
        charly
      end
    end

    alpha = @engine.register_participant :alpha, Ruote::HashParticipant
    bravo = @engine.register_participant :bravo, Ruote::HashParticipant
    charly = @engine.register_participant :charly, Ruote::HashParticipant

    noisy

    #
    # reaching initial situation...

    wfid = @engine.launch(pdef)
    wait_for(:alpha)

    alpha.reply(alpha.first)
    wait_for(:bravo)

    #
    # rewinding...

    wi = bravo.first

    wi.fei.expid = wi.fei.expid[0..-3] # parent wfid
    wi.fields['__command__'] = [ 'jump', 'alpha' ]

    @engine.reply(wi)

    #
    # workitem is back to alpha

    wait_for(:alpha)
  end
end

