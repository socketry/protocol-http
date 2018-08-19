# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'frame'

module HTTP
	module Protocol
		module HTTP2
			module Continued
				def initialize(*)
					super
					
					@continuation = nil
				end
				
				def end_headers?
					flag_set?(END_HEADERS)
				end
				
				def read(io)
					super
					
					unless end_headers?
						@continuation = ContinuationFrame.new
						
						@continuation.read(io)
					end
				end
				
				def write(io)
					super
					
					if continuation = self.continuation
						continuation.write(io)
					end
				end
				
				attr_accessor :continuation
				
				def pack(data, **options)
					maximum_size = options[:maximum_size]
					
					if maximum_size and data.bytesize > maximum_size
						clear_flags(END_HEADERS)
						
						super(data.byteslice(0, maximum_size), **options)
						
						remainder = data.byteslice(maximum_size, data.bytesize-maximum_size)
						
						@continuation = ContinuationFrame.new
						@continuation.pack(remainder, maximum_size: maximum_size)
					else
						set_flags(END_HEADERS)
						
						super data, **options
						
						@continuation = nil
					end
				end
				
				def unpack
					if @continuation.nil?
						super
					else
						super + @continuation.unpack
					end
				end
			end
			
			# The CONTINUATION frame is used to continue a sequence of header block fragments. Any number of CONTINUATION frames can be sent, as long as the preceding frame is on the same stream and is a HEADERS, PUSH_PROMISE, or CONTINUATION frame without the END_HEADERS flag set.
			#
			# +---------------------------------------------------------------+
			# |                   Header Block Fragment (*)                 ...
			# +---------------------------------------------------------------+
			#
			class ContinuationFrame < Frame
				include Continued
				
				TYPE = 0x9
			end
		end
	end
end
