# frozen_string_literal: true
#
# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'url'

module Protocol
	module HTTP
		# Represents an individual cookie key-value pair.
		class Cookie
			def initialize(name, value, directives)
				@name = name
				@value = value
				@directives = directives
			end
			
			def encoded_name
				URL.escape(@name)
			end
			
			def encoded_value
				URL.escape(@value)
			end
			
			def to_str
				buffer = String.new.b
				
				buffer << encoded_name << '=' << encoded_value
				
				if @directives
					@directives.collect do |key, value|
						buffer << ';'
						
						case value
						when String
							buffer << key << '=' << value
						when TrueClass
							buffer << key
						end
					end
				end
				
				return buffer
			end
			
			def self.parse string
				head, *options = string.split(/\s*;\s*/)
				
				key, value = head.split('=')
				directives.collect{|directive| directive.split('=', 2)}.to_h
				
				self.new(
					URI.decode(key),
					URI.decode(value),
					directives,
				)
			end
		end
	end
end
