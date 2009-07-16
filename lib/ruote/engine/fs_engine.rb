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


require 'ruote/engine/engine'
require 'ruote/err/fs_ejournal'
require 'ruote/evt/fs_tracker'
require 'ruote/time/fs_scheduler'
require 'ruote/storage/fs_storage'


module Ruote

  #
  # A ruote engine with persistence to the filesystem (usually under ./work/)
  #
  class FsPersistedEngine < Engine

    protected

    def build_expression_storage

      init_storage(Ruote::FsStorage)
    end

    def build_tracker

      add_service(:s_tracker, Ruote::FsTracker)
    end

    def build_scheduler

      add_service(:s_scheduler, Ruote::FsScheduler)
    end

    def build_error_journal

      add_service(:s_ejournal, Ruote::FsErrorJournal)
    end
  end
end
