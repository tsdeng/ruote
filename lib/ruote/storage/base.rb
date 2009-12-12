#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


module Ruote

  #
  # Base methods for storage implementations.
  #
  module StorageBase

    def reserve (doc)

      (delete(doc) != true)
    end

    #--
    # configurations
    #++

    def get_configuration (key)

      get('configurations', key)
    end

    #--
    # messages
    #++

    def put_msg (action, options)

      # merge! is way faster than merge (no object creation probably)

      put(options.merge!(
        'type' => 'msgs',
        '_id' => "#{$$}-#{Thread.current.object_id}-#{Time.now.to_f.to_s}",
        'action' => action))

      #(@local_msgs ||= []) << options
    end

    #def get_local_msgs
    #  if @msgs
    #    msgs = @msgs
    #    @msgs = nil
    #    return msgs
    #  end
    #  []
    #end

    def get_msgs

      get_many(
        'msgs', nil, :limit => 300
      ).sort { |a, b|
        a['put_at'] <=> b['put_at']
      }
    end

    #--
    # expressions
    #++

    def find_root_expression (wfid)

      get_many('expressions', /#{wfid}$/).sort { |a, b|
        a['fei']['expid'] <=> b['fei']['expid']
      }.select { |e|
        e['parent_id'].nil?
      }.first
    end

    #--
    # trackers
    #++

    def get_trackers

      get('variables', 'trackers') ||
        { '_id' => 'trackers', 'type' => 'variables', 'trackers' => {} }
    end

    #--
    # ats and crons
    #++

    def get_ats (delta, now)

      if delta < 2.0

        at = now.strftime('%Y%m%d%H%M%S')
        get_many('ats', /-#{at}$/)

      elsif delta < 60.0

        at = now.strftime('%Y%m%d%H%M')
        ats = get_many('ats', /-#{at}\d\d$/)
        filter_ats(ats, now)

      else # load all the ats...

        ats = get_many('ats')
        filter_ats(ats, now)
      end
    end

    def get_crons (delta, now)

      # TODO : implement me

      []
    end

    def put_at_schedule (owner_fei, at, msg)

      if at < Time.now.utc + 1.0
        #
        # trigger immediately
        #
        put_msg(msg.delete('action'), msg)
        #
      else
        #
        # schedule
        #
        put_schedule('ats', owner_fei, at, msg)
      end
    end

    def put_cron_schedule (owner_fei, cron, msg)

      put_schedule('crons', owner_fei, cron, msg)
    end

    def delete_at_schedule (schedule_id)

      s = get('ats', schedule_id)
      delete(s) if s
    end

    def delete_cron_schedule (schedule_id)

      s = get('crons', schedule_id)
      delete(s) if s
    end

    #--
    # engine variables
    #++

    def get_engine_variable (k)

      get_engine_variables['variables'][k]
    end

    def put_engine_variable (k, v)

      vars = get_engine_variables
      vars['variables'][k] = v

      put_engine_variable(k, v) unless put(vars).nil?
    end

    protected

    def get_engine_variables

      get('variables', 'variables') || {
        'type' => 'variables', '_id' => 'variables', 'variables' => {} }
    end

    def put_schedule (type, owner_fei, t, msg)

      h = { 'type' => type, 'owner' => owner_fei, 'msg' => msg }

      if type == 'ats'

        at = t.strftime('%Y%m%d%H%M%S')
        h['_id'] = "#{Ruote.to_storage_id(owner_fei)}-#{at}"
        h['at'] = Ruote.time_to_utc_s(t)

      else

        raise "implement me !"
      end

      put(h)

      h['_id']
    end

    # Returns all the ats whose due date arrived (now or earlier)
    #
    def filter_ats (ats, now)

      now = Ruote.time_to_utc_s(now)

      ats.select { |at| at['at'] <= now }
    end
  end
end

