# frozen_string_literal: true

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

require_relative 'header/split'
require_relative 'header/multiple'
require_relative 'header/cookie'
require_relative 'header/connection'
require_relative 'header/cache_control'
require_relative 'header/etags'
require_relative 'header/vary'

module Protocol
	module HTTP
		# Headers are an array of key-value pairs. Some header keys represent multiple values.
		class Headers
			Split = Header::Split
			Multiple = Header::Multiple
			
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
					@indexed = nil
				end
			end
			
			def dup
				self.class.new(@fields, @indexed)
			end
			
			def clear
				@fields.clear
				@indexed = nil
			end
			
			# An array of `[key, value]` pairs.
			attr :fields
			
			def freeze
				return if frozen?
				
				# Ensure @indexed is generated:
				self.to_h
				
				@fields.freeze
				@indexed.freeze
				
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
			
			def extract(keys)
				deleted, @fields = @fields.partition do |field|
					keys.include?(field.first.downcase)
				end
				
				if @indexed
					keys.each do |key|
						@indexed.delete(key)
					end
				end
				
				return deleted
			end
			
			# This is deprecated.
			alias slice! extract
			
			# Add the specified header key value pair.
			# @param key [String] the header key.
			# @param value [String] the header value to assign.
			def add(key, value)
				self[key] = value
			end
			
			# Set the specified header key to the specified value, replacing any existing header keys with the same name.
			# @param key [String] the header key to replace.
			# @param value [String] the header value to assign.
			def set(key, value)
				# TODO This could be a bit more efficient:
				self.delete(key)
				self.add(key, value)
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
				if @indexed
					merge_into(@indexed, key.downcase, value)
				end
				
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
				
				'connection' => Header::Connection,
				'cache-control' => Header::CacheControl,
				'vary' => Header::Vary,
				
				# Headers specifically for proxies:
				'via' => Split,
				'x-forwarded-for' => Split,
				
				# Cache validations:
				'if-match' => Header::ETags,
				'if-none-match' => Header::ETags,
				
				# Headers which may be specified multiple times, but which can't be concatenated:
				'www-authenticate' => Multiple,
				'proxy-authenticate' => Multiple,
				
				# Custom headers:
				'set-cookie' => Header::SetCookie,
				'cookie' => Header::Cookie,
			}.tap{|hash| hash.default = Split}
			
			# Delete all headers with the given key, and return the merged value.
			def delete(key)
				deleted, @fields = @fields.partition do |field|
					field.first.downcase == key
				end
				
				if deleted.empty?
					return nil
				end
				
				if @indexed
					return @indexed.delete(key)
				elsif policy = MERGE_POLICY[key]
					(key, value), *tail = deleted
					merged = policy.new(value)
					
					tail.each{|k,v| merged << v}
					
					return merged
				else
					key, value = deleted.last
					return value
				end
			end
			
			protected def merge_into(hash, key, value)
				if policy = MERGE_POLICY[key]
					if current_value = hash[key]
						current_value << value
					else
						hash[key] = policy.new(value)
					end
				else
					# We can't merge these, we only expose the last one set.
					hash[key] = value
				end
			end
			
			def [] key
				to_h[key]
			end
			
			# A hash table of `{key, policy[key].map(values)}`
			def to_h
				@indexed ||= @fields.inject({}) do |hash, (key, value)|
					merge_into(hash, key.downcase, value)
					
					hash
				end
			end
			
			def inspect
				"#<#{self.class} #{@fields.inspect}>"
			end
			
			def == other
				case other
				when Hash
					to_h == other
				when Headers
					@fields == other.fields
				else
					@fields == other
				end
			end
			
			# Used for merging objects into a sequential list of headers. Normalizes header keys and values.
			class Merged
				include Enumerable
				
				def initialize(*all)
					@all = all
				end
				
				def clear
					@all.clear
				end
				
				def << headers
					@all << headers
					
					return self
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
