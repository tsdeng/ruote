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

  def Ruote.lookup (collection, key)

    key, rest = pop_key(key)
    value = flookup(collection, key)

    return value unless rest
    return nil if value == nil

    lookup(value, rest)
  end

  protected

  def Ruote.pop_key (key)

    i = key.index('.')

    i ? [ narrow_key(key[0..i-1]), key[i+1..-1] ] : [ narrow_key(key), nil ]
  end

  def Ruote.narrow_key (key)

    return 0 if key == '0'

    i = key.to_i
    return i if i != 0

    key
  end

  def Ruote.flookup (collection, key)

    value = (collection[key] rescue nil)

    if value == nil and key.is_a?(Fixnum)
      value = (collection[key.to_s] rescue nil)
    end

    value
  end
end
