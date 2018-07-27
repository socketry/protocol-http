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
require_relative 'padded'

module HTTP
	module Protocol
		module HTTP2
			# The PUSH_PROMISE frame is used to notify the peer endpoint in advance of streams the sender intends to initiate. The PUSH_PROMISE frame includes the unsigned 31-bit identifier of the stream the endpoint plans to create along with a set of headers that provide additional context for the stream.
			# 
			# +---------------+
			# |Pad Length? (8)|
			# +-+-------------+-----------------------------------------------+
			# |R|                  Promised Stream ID (31)                    |
			# +-+-----------------------------+-------------------------------+
			# |                   Header Block Fragment (*)                 ...
			# +---------------------------------------------------------------+
			# |                           Padding (*)                       ...
			# +---------------------------------------------------------------+
			#
			class PushPromiseFrame < Frame
				include Continued, Padded
				
				TYPE = 0x5
				FORMAT = "N".freeze
				
				def end_headers?
					flag_set?(END_HEADERS)
				end
				
				def unpack
					data = super
					
					stream_id = data.unpack(FORMAT).first
					
					return stream_id, data.byteslice(4, data.bytesize - 4)
				end
				
				def pack(stream_id, data, *args)
					super([stream_id].pack(FORMAT) + data, *args)
				end
			end
		end
	end
end
