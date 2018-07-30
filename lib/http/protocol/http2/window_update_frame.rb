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

module HTTP
	module Protocol
		module HTTP2
			class Window
				def initialize(capacity)
					@used = 0
					@capacity = capacity
					
					fail unless capacity
				end
				
				def dup
					return self.class.new(@capacity)
				end
				
				attr_accessor :used
				attr_accessor :capacity
				
				def consume(amount)
					@used += amount
				end
				
				def available
					@capacity - @used
				end
				
				def expand(amount)
					@used -= amount
				end
				
				def limited?
					@used > (@capacity / 2)
				end
			end
			
			# The WINDOW_UPDATE frame is used to implement flow control.
			#
			# +-+-------------------------------------------------------------+
			# |R|              Window Size Increment (31)                     |
			# +-+-------------------------------------------------------------+
			#
			class WindowUpdateFrame < Frame
				TYPE = 0x8
				FORMAT = "N"
				
				def pack(window_size_increment)
					super [window_size_increment].pack(FORMAT)
				end
				
				def unpack
					super.unpack(FORMAT).first
				end
				
				def apply(connection)
					connection.receive_window_update(self)
				end
			end
		end
	end
end
