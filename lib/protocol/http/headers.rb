# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

require_relative "header/split"
require_relative "header/multiple"
require_relative "header/cookie"
require_relative "header/connection"
require_relative "header/cache_control"
require_relative "header/etag"
require_relative "header/etags"
require_relative "header/vary"
require_relative "header/authorization"
require_relative "header/date"
require_relative "header/priority"

module Protocol
	module HTTP
		# @namespace
		module Header
		end
		
		# Headers are an array of key-value pairs. Some header keys represent multiple values.
		class Headers
			Split = Header::Split
			Multiple = Header::Multiple
			
			TRAILER = "trailer"
			
			# Construct an instance from a headers Array or Hash. No-op if already an instance of `Headers`. If the underlying array is frozen, it will be duped.
			#
			# @return [Headers] an instance of headers.
			def self.[] headers
				if headers.nil?
					return self.new
				end
				
				if headers.is_a?(self)
					if headers.frozen?
						return headers.dup
					else
						return headers
					end
				end
				
				fields = headers.to_a
				
				if fields.frozen?
					fields = fields.dup
				end
				
				return self.new(fields)
			end
			
			# Initialize the headers with the specified fields.
			#
			# @parameter fields [Array] An array of `[key, value]` pairs.
			# @parameter indexed [Hash] A hash table of normalized headers, if available.
			def initialize(fields = [], indexed = nil)
				@fields = fields
				@indexed = indexed
				
				# Marks where trailer start in the @fields array.
				@tail = nil
			end
			
			# Initialize a copy of the headers.
			#
			# @parameter other [Headers] The headers to copy.
			def initialize_dup(other)
				super
				
				@fields = @fields.dup
				@indexed = @indexed.dup
			end
			
			# Clear all headers.
			def clear
				@fields.clear
				@indexed = nil
				@tail = nil
			end
			
			# Flatten trailer into the headers, in-place.
			def flatten!
				if @tail
					self.delete(TRAILER)
					@tail = nil
				end
				
				return self
			end
			
			# Flatten trailer into the headers, returning a new instance of {Headers}.
			def flatten
				self.dup.flatten!
			end
			
			# @attribute [Array] An array of `[key, value]` pairs.
			attr :fields
			
			# @returns [Boolean] Whether there are any trailers.
			def trailer?
				@tail != nil
			end
			
			# Record the current headers, and prepare to add trailers.
			#
			# This method is typically used after headers are sent to capture any additional headers which should then be sent as trailers.
			#
			# A sender that intends to generate one or more trailer fields in a message should generate a trailer header field in the header section of that message to indicate which fields might be present in the trailers.
			#
			# @parameter names [Array] The trailer header names which will be added later.
			# @yields {|name, value| ...} the trailing headers if a block is given.
			# @returns An enumerator which is suitable for iterating over trailers.
			def trailer!(&block)
				@tail ||= @fields.size
				
				return trailer(&block)
			end
			
			# Enumerate all headers in the trailer, if there are any.
			def trailer(&block)
				return to_enum(:trailer) unless block_given?
				
				if @tail
					@fields.drop(@tail).each(&block)
				end
			end
			
			# Freeze the headers, and ensure the indexed hash is generated.
			def freeze
				return if frozen?
				
				# Ensure @indexed is generated:
				self.to_h
				
				@fields.freeze
				@indexed.freeze
				
				super
			end
			
			# @returns [Boolean] Whether the headers are empty.
			def empty?
				@fields.empty?
			end
			
			# Enumerate all header keys and values.
			#
			# @yields {|key, value| ...}
			# 	@parameter key [String] The header key.
			# 	@parameter value [String] The header value.
			def each(&block)
				@fields.each(&block)
			end
			
			# @returns [Boolean] Whether the headers include the specified key.
			def include? key
				self[key] != nil
			end
			
			alias key? include?
			
			# @returns [Array] All the keys of the headers.
			def keys
				self.to_h.keys
			end
			
			# Extract the specified keys from the headers.
			#
			# @parameter keys [Array] The keys to extract.
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
			
			# Add the specified header key value pair.
			#
			# @parameter key [String] the header key.
			# @parameter value [String] the header value to assign.
			def add(key, value)
				self[key] = value
			end
			
			# Set the specified header key to the specified value, replacing any existing header keys with the same name.
			#
			# @parameter key [String] the header key to replace.
			# @parameter value [String] the header value to assign.
			def set(key, value)
				# TODO This could be a bit more efficient:
				self.delete(key)
				self.add(key, value)
			end
			
			# Merge the headers into this instance.
			def merge!(headers)
				headers.each do |key, value|
					self[key] = value
				end
				
				return self
			end
			
			# Merge the headers into a new instance of {Headers}.
			def merge(headers)
				self.dup.merge!(headers)
			end
			
			# Append the value to the given key. Some values can be appended multiple times, others can only be set once.
			#
			# @parameter key [String] The header key.
			# @parameter value [String] The header value.
			def []= key, value
				if @indexed
					merge_into(@indexed, key.downcase, value)
				end
				
				@fields << [key, value]
			end
			
			# The policy for various headers, including how they are merged and normalized.
			POLICY = {
				# Headers which may only be specified once:
				"content-type" => false,
				"content-disposition" => false,
				"content-length" => false,
				"user-agent" => false,
				"referer" => false,
				"host" => false,
				"from" => false,
				"location" => false,
				"max-forwards" => false,
				"retry-after" => false,
				
				# Custom headers:
				"connection" => Header::Connection,
				"cache-control" => Header::CacheControl,
				"vary" => Header::Vary,
				"priority" => Header::Priority,
				
				# Headers specifically for proxies:
				"via" => Split,
				"x-forwarded-for" => Split,
				
				# Authorization headers:
				"authorization" => Header::Authorization,
				"proxy-authorization" => Header::Authorization,
				
				# Cache validations:
				"etag" => Header::ETag,
				"if-match" => Header::ETags,
				"if-none-match" => Header::ETags,
				
				# Headers which may be specified multiple times, but which can't be concatenated:
				"www-authenticate" => Multiple,
				"proxy-authenticate" => Multiple,
				
				# Custom headers:
				"set-cookie" => Header::SetCookie,
				"cookie" => Header::Cookie,
				
				# Date headers:
				# These headers include a comma as part of the formatting so they can't be concatenated.
				"date" => Header::Date,
				"expires" => Header::Date,
				"last-modified" => Header::Date,
				"if-modified-since" => Header::Date,
				"if-unmodified-since" => Header::Date,
			}.tap{|hash| hash.default = Split}
			
			# Delete all header values for the given key, and return the merged value.
			#
			# @parameter key [String] The header key.
			# @returns [String | Array | Object] The merged header value.
			def delete(key)
				deleted, @fields = @fields.partition do |field|
					field.first.downcase == key
				end
				
				if deleted.empty?
					return nil
				end
				
				if @indexed
					return @indexed.delete(key)
				elsif policy = POLICY[key]
					(key, value), *tail = deleted
					merged = policy.new(value)
					
					tail.each{|k,v| merged << v}
					
					return merged
				else
					key, value = deleted.last
					return value
				end
			end
			
			# Merge the value into the hash according to the policy for the given key.
			# 
			# @parameter hash [Hash] The hash to merge into.
			# @parameter key [String] The header key.
			# @parameter value [String] The raw header value.
			protected def merge_into(hash, key, value)
				if policy = POLICY[key]
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
			
			# Get the value of the specified header key.
			#
			# @parameter key [String] The header key.
			# @returns [String | Array | Object] The header value.
			def [] key
				to_h[key]
			end
			
			# Compute a hash table of headers, where the keys are normalized to lower case and the values are normalized according to the policy for that header.
			#
			# @returns [Hash] A hash table of `{key, value}` pairs.
			def to_h
				@indexed ||= @fields.inject({}) do |hash, (key, value)|
					merge_into(hash, key.downcase, value)
					
					hash
				end
			end
			
			alias as_json to_h
			
			# Inspect the headers.
			#
			# @returns [String] A string representation of the headers.
			def inspect
				"#<#{self.class} #{@fields.inspect}>"
			end
			
			# Compare this object to another object. May depend on the order of the fields.
			#
			# @returns [Boolean] Whether the other object is equal to this one.
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
				
				# Construct a merged list of headers.
				#
				# @parameter *all [Array] An array of all headers to merge.
				def initialize(*all)
					@all = all
				end
				
				# @returns [Array] A list of all headers, in the order they were added, as `[key, value]` pairs.
				def fields
					each.to_a
				end
				
				# @returns [Headers] A new instance of {Headers} containing all the merged headers.
				def flatten
					Headers.new(fields)
				end
				
				# Clear the references to all headers.
				def clear
					@all.clear
				end
				
				# Add a new set of headers to the merged list.
				#
				# @parameter headers [Headers | Array | Hash] A list of headers to add.
				def << headers
					@all << headers
					
					return self
				end
				
				# Enumerate all headers in the merged list.
				#
				# @yields {|key, value| ...} The header key and value.
				# 	@parameter key [String] The header key (lower case).
				# 	@parameter value [String] The header value.
				def each(&block)
					return to_enum unless block_given?
					
					@all.each do |headers|
						headers.each do |key, value|
							yield key.to_s.downcase, value.to_s
						end
					end
				end
			end
		end
	end
end
