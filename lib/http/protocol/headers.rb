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

module HTTP
	module Protocol
		CONTENT_LENGTH = 'content-length'.freeze
		
		TRANSFER_ENCODING = 'transfer-encoding'.freeze
		CHUNKED = 'chunked'.freeze
		
		CONNECTION = 'connection'.freeze
		CLOSE = 'close'.freeze
		KEEP_ALIVE = 'keep-alive'.freeze
		
		HOST = 'host'.freeze
		
		class Headers
			class Split < Array
				COMMA = /\s*,\s*/
				
				def initialize(value)
					super(value.split(COMMA))
				end
				
				def << value
					super value.split(COMMA)
				end
				
				def to_s
					join(", ")
				end
			end
			
			class Multiple < Array
				def initialize(value)
					super()
					
					self << value
				end
				
				def to_s
					join("\n")
				end
			end
			
			def self.[] hash
				self.new(hash.to_a)
			end
			
			def initialize(fields = nil, indexed = nil)
				if fields
					@fields = fields.dup
				else
					@fields = []
				end
				
				if indexed
					@indexed = indexed.dup
				else
					@indexed = self.to_h
				end
			end
			
			def dup
				self.class.new(@fields, @indexed)
			end
			
			attr :fields
			
			def freeze
				return if frozen?
				
				@indexed = to_h
				
				super
			end
			
			def empty?
				@fields.empty?
			end
			
			def each(&block)
				@fields.each(&block)
			end
			
			def include? key
				self[key] != nil
			end
			
			def slice!(keys)
				_, @fields = @fields.partition do |field|
					keys.include?(field.first.downcase)
				end
				
				keys.each do |key|
					@indexed.delete(key)
				end
				
				return self
			end
			
			def slice(keys)
				self.dup.slice!(keys)
			end
			
			def add(key, value)
				self[key] = value
			end
			
			def merge!(headers)
				headers.each do |key, value|
					self[key] = value
				end
				
				return self
			end
			
			def merge(headers)
				self.dup.merge!(headers)
			end
			
			# Append the value to the given key. Some values can be appended multiple times, others can only be set once.
			# @param key [String] The header key.
			# @param value The header value.
			def []= key, value
				merge_into(@indexed, key.downcase, value)
				
				@fields << [key, value]
			end
			
			MERGE_POLICY = {
				# Headers which may only be specified once.
				'content-type' => false,
				'content-disposition' => false,
				'content-length' => false,
				'user-agent' => false,
				'referer' => false,
				'host' => false,
				'authorization' => false,
				'proxy-authorization' => false,
				'if-modified-since' => false,
				'if-unmodified-since' => false,
				'from' => false,
				'location' => false,
				'max-forwards' => false,
				
				'connection' => Split,
				
				# Headers specifically for proxies:
				'via' => Split,
				'x-forwarded-for' => Split,
				
				# Headers which may be specified multiple times, but which can't be concatenated.
				'set-cookie' => Multiple,
				'www-authenticate' => Multiple,
				'proxy-authenticate' => Multiple
			}.tap{|hash| hash.default = Split}
			
			# Delete all headers with the given key, and return the merged value.
			def delete(key)
				_, @fields = @fields.partition do |field|
					field.first.downcase == key
				end
				
				return @indexed.delete(key)
			end
			
			protected def merge_into(hash, key, value)
				if policy = MERGE_POLICY[key]
					if current_value = hash[key]
						current_value << value
					else
						hash[key] = policy.new(value)
					end
				else
					raise ArgumentError, "Header #{key} can only be set once!" if hash.include?(key)
					
					# We can't merge these, we only expose the last one set.
					hash[key] = value
				end
			end
			
			def [] key
				@indexed[key]
			end
			
			def to_h
				@fields.inject({}) do |hash, (key, value)|
					merge_into(hash, key.downcase, value)
					
					hash
				end
			end
			
			def == other
				if other.is_a? Hash
					to_h == other
				else
					@fields == other.fields
				end
			end
			
			# Used for merging objects into a sequential list of headers. Normalizes header keys and values.
			class Merged
				def initialize(*all)
					@all = all
				end
				
				def << headers
					@all << headers
				end
				
				# @yield [String, String] header key (lower case) and value (as string).
				def each(&block)
					@all.each do |headers|
						headers.each do |key, value|
							yield key.downcase, value.to_s
						end
					end
				end
			end
		end
	end
end
