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
				# @param capacity [Integer] The initial window size, typically from the settings.
				def initialize(capacity = 0xFFFF)
					# This is the main field required:
					@available = capacity
					
					# These two fields are primarily used for efficiently sending window updates:
					@used = 0
					@capacity = capacity
					
					fail unless capacity
				end
				
				def dup
					return self.class.new(@capacity)
				end
				
				# The window is completely full?
				def full?
					@available.zero?
				end
				
				attr :used
				attr :capacity
				
				# When the value of SETTINGS_INITIAL_WINDOW_SIZE changes, a receiver MUST adjust the size of all stream flow-control windows that it maintains by the difference between the new value and the old value.
				def capacity= value
					difference = value - @capacity
					@available += difference
				end
				
				def consume(amount)
					@available -= amount
					@used += amount
				end
				
				attr :available
				
				def available?
					@available > 0
				end
				
				def expand(amount)
					@available += amount
					@used -= amount
				end
				
				def limited?
					@available < (@capacity / 2)
				end
				
				def to_s
					"\#<Window used=#{@used} available=#{@available} capacity=#{@capacity}>"
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
