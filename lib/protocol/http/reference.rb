# frozen_string_literal: true
#
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

require_relative 'url'

module Protocol
	module HTTP
		# A relative reference, excluding any authority.
		class Reference
			include Comparable
			
			# Generate a reference from a path and user parameters. The path may contain a `#fragment` or `?query=parameters`.
			def self.parse(path = '/', parameters = nil)
				base, fragment = path.split('#', 2)
				path, query_string = base.split('?', 2)
				
				self.new(path, query_string, fragment, parameters)
			end
			
			def initialize(path = '/', query_string = nil, fragment = nil, parameters = nil)
				@path = path
				@query_string = query_string
				@fragment = fragment
				@parameters = parameters
			end
			
			# The path component, e.g. /foo/bar/index.html
			attr_accessor :path
			
			# The un-parsed query string, e.g. 'x=10&y=20'
			attr_accessor :query_string
			
			# A fragment, the part after the '#'
			attr_accessor :fragment
			
			# User supplied parameters that will be appended to the query part.
			attr_accessor :parameters
			
			def freeze
				return self if frozen?
				
				@path.freeze
				@query_string.freeze
				@fragment.freeze
				@parameters.freeze
				
				super
			end
			
			def to_ary
				[@path, @query_string, @fragment, @parameters]
			end
			
			def <=> other
				to_ary <=> other.to_ary
			end
			
			def self.[] reference
				if reference.is_a? self
					return reference
				else
					return self.parse(reference)
				end
			end
			
			def parameters?
				@parameters and !@parameters.empty?
			end
			
			def query_string?
				@query_string and !@query_string.empty?
			end
			
			def fragment?
				@fragment and !@fragment.empty?
			end
			
			def append(buffer)
				if query_string?
					buffer << URL.escape_path(@path) << '?' << @query_string
					buffer << '&' << URL.encode(@parameters) if parameters?
				else
					buffer << URL.escape_path(@path)
					buffer << '?' << URL.encode(@parameters) if parameters?
				end
				
				if fragment?
					buffer << '#' << URL.escape(@fragment)
				end
				
				return buffer
			end
			
			def to_str
				append(String.new)
			end
			
			alias to_s to_str
			
			def + other
				other = self.class[other]
				
				self.class.new(
					expand_path(self.path, other.path),
					other.query_string,
					other.fragment,
					other.parameters,
				)
			end
			
			def dup(path = nil, parameters = nil, merge = true)
				if merge and @parameters
					if parameters
						parameters = @parameters.merge(parameters)
					else
						parameters = @parameters
					end
				end
				
				if path
					path = expand_path(@path, path)
				else
					path = @path
				end
				
				self.class.new(path, @query_string, @fragment, parameters)
			end
			
			private
			
			def split(path)
				if path.empty?
					[path]
				else
					path.split('/', -1)
				end
			end
			
			def expand_path(base, relative)
				if relative.start_with? '/'
					return relative
				else
					path = split(base)
					# drop the last path element for relative computations, e.g.
					# /foo/bar/index.html -> /foo/bar/#{relative}
					path.pop 
					
					parts = split(relative)
					
					parts.each do |part|
						if part == '..'
							path.pop
						else
							path << part
						end
					end
					
					return path.join('/')
				end
			end
		end
	end
end
