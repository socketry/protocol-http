# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.
# Copyright, 2023, by Thomas Morgan.

require_relative "split"
require_relative "quoted_string"
require_relative "../error"

module Protocol
	module HTTP
		module Header
			# The `accept-content-type` header represents a list of content-types that the client can accept.
			class Accept < Array
				# Regular expression used to split values on commas, with optional surrounding whitespace, taking into account quoted strings.
				SPLIT = /
					(?:            # Start non-capturing group
						"[^"\\]*"    # Match quoted strings (no escaping of quotes within)
						|            # OR
						[^,"]+       # Match non-quoted strings until a comma or quote
					)+
					(?=,|\z)       # Match until a comma or end of string
				/x
				
				ParseError = Class.new(Error)
				
				MEDIA_RANGE = /\A(?<type>#{TOKEN})\/(?<subtype>#{TOKEN})(?<parameters>.*)\z/
				
				PARAMETER = /\s*;\s*(?<key>#{TOKEN})=((?<value>#{TOKEN})|(?<quoted_value>#{QUOTED_STRING}))/
				
				# A single entry in the Accept: header, which includes a mime type and associated parameters.
				MediaRange = Struct.new(:type, :subtype, :parameters) do
					def initialize(type, subtype = '*', parameters = {})
						super(type, subtype, parameters)
					end
					
					def <=> other
						other.quality_factor <=> self.quality_factor
					end
					
					def parameters_string
						return '' if parameters == nil or parameters.empty?
						
						parameters.collect do |key, value|
							"; #{key.to_s}=#{QuotedString.quote(value.to_s)}"
						end.join
					end
					
					def === other
						if other.is_a? self.class
							super
						else
							return self.mime_type === other
						end
					end
					
					def mime_type
						"#{type}/#{subtype}"
					end
					
					def to_s
						"#{type}/#{subtype}#{parameters_string}"
					end
					
					alias to_str to_s
					
					def quality_factor
						parameters.fetch('q', 1.0).to_f
					end
					
					def split(*args)
						return [type, subtype]
					end
				end
				
				def initialize(value = nil)
					if value
						super(value.scan(SPLIT).map(&:strip))
					else
					end
				end
				
				# Adds one or more comma-separated values to the header.
				#
				# The input string is split into distinct entries and appended to the array.
				#
				# @parameter value [String] the value or values to add, separated by commas.
				def << (value)
					self.concat(value.scan(SPLIT).map(&:strip))
				end
				
				# Serializes the stored values into a comma-separated string.
				#
				# @returns [String] the serialized representation of the header values.
				def to_s
					join(",")
				end
				
				# Parse the `accept` header.
				#
				# @returns [Array(Charset)] the list of content types and their associated parameters.
				def media_ranges
					self.map do |value|
						self.parse_media_range(value)
					end
				end
				
				private
				
				def parse_media_range(value)
					if match = value.match(MEDIA_RANGE)
						type = match[:type]
						subtype = match[:subtype]
						parameters = {}
						
						match[:parameters].scan(PARAMETER) do |key, value, quoted_value|
							parameters[key] = quoted_value || value
						end
						
						return MediaRange.new(type, subtype, parameters)
					else
						raise ArgumentError, "Invalid media type: #{value.inspect}"
					end
				end
			end
		end
	end
end
