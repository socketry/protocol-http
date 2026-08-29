# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.
# Copyright, 2025, by William T. Nelson.

require_relative "split"
require_relative "../quoted_string"
require_relative "../error"

module Protocol
	module HTTP
		module Header
			# The `accept-content-type` header represents a list of content-types that the client can accept.
			class Accept < Split
				# Regular expression used to split values on commas, with optional surrounding whitespace, taking into account quoted strings.
				SEPARATOR = /
					(?:                       # Start non-capturing group
						"(?:[^"\\]|\\.)*"       # Match quoted strings, including quoted pairs
						|                       # OR
						[^,"]+                  # Match non-quoted strings until a comma or quote
					)+
					(?=,|\z)                  # Match until a comma or end of string
				/x
				
				ParseError = Class.new(Error) do
					include BadRequest
				end
				
				MEDIA_RANGE = /\A(?<type>#{TOKEN})\/(?<subtype>#{TOKEN})(?<parameters>.*)\z/
				
				PARAMETER = /\s*;\s*(?<key>#{TOKEN})=((?<value>#{TOKEN})|(?<quoted_value>#{QUOTED_STRING}))/
				
				# A single entry in the Accept: header, which includes a mime type and associated parameters. A media range can include wild cards, but a media type is a specific type and subtype.
				MediaRange = Struct.new(:type, :subtype, :parameters) do
					# Create a new media range.
					#
					# @parameter type [String] the type of the media range.
					# @parameter subtype [String] the subtype of the media range.
					# @parameter parameters [Hash] the parameters associated with the media range.
					def initialize(type, subtype = "*", parameters = {})
						super(type, subtype, parameters)
					end
					
					# Compare the media range with another media range or a string, based on the quality factor.
					def <=> other
						other.quality_factor <=> self.quality_factor
					end
					
					private def parameters_string
						return "" if parameters == nil or parameters.empty?
						
						parameters.collect do |key, value|
							";#{key.to_s}=#{QuotedString.quote(value.to_s)}"
						end.join
					end
					
					# The string representation of the media range, including the type, subtype, and any parameters.
					def to_s
						"#{type}/#{subtype}#{parameters_string}"
					end
					
					alias to_str to_s
					
					# The quality factor associated with the media range, which is used to determine the order of preference.
					#
					# @returns [Float] the quality factor, which defaults to 1.0 if not specified.
					def quality_factor
						parameters.fetch("q", 1.0).to_f
					end
				end
				
				# Parses a raw header value.
				#
				# @parameter value [String] a raw header value containing comma-separated media types.
				# @returns [Accept] a new instance containing the parsed media types.
				def self.parse(value)
					self.new(value.scan(SEPARATOR).map(&:strip))
				end
				
				# Adds one or more comma-separated values to the header.
				#
				# The input string is split into distinct entries and appended to the array.
				#
				# @parameter value [String] a raw header value containing one or more media types separated by commas.
				def << value
					self.concat(value.scan(SEPARATOR).map(&:strip))
				end
				
				# Converts the parsed header value into a raw header value.
				#
				# @returns [String] a raw header value (comma-separated string).
				def to_s
					join(",")
				end
				
				# Whether this header is acceptable in HTTP trailers.
				# @returns [Boolean] `false`, as Accept headers are used for response content negotiation.
				def self.trailer?
					false
				end
				
				# Parse the `accept` header.
				#
				# @returns [Array(Charset)] the list of content types and their associated parameters.
				def media_ranges
					self.map do |value|
						self.parse_media_range(value)
					end
				end
				
				# Parse the `accept` header and order media ranges by preference.
				#
				# Media ranges with equal quality factors retain their original relative order.
				#
				# @returns [Array(MediaRange)] the preferred media ranges.
				def preferred_media_ranges
					sort_by_quality_factor(media_ranges)
				end
				
				private
				
				def parse_media_range(value)
					if match = value.match(MEDIA_RANGE)
						type = match[:type]
						subtype = match[:subtype]
						parameters = {}
						parameters_string = match[:parameters]
						offset = 0
						
						parameters_string.scan(PARAMETER) do |key, value, quoted_value|
							parameter_match = Regexp.last_match
							unless parameter_match.begin(0) == offset
								raise ParseError, "Invalid media range parameters: #{parameters_string[offset..].inspect}"
							end
							offset = parameter_match.end(0)
							
							if key.casecmp?("q")
								if quoted_value || parameters.key?("q") || !value.match?(/\A(?:#{QVALUE})\z/)
									raise ParseError, "Invalid quality factor: #{value.inspect}"
								end
								
								key = "q"
							end
							
							if quoted_value
								value = QuotedString.unquote(quoted_value)
							end
							
							parameters[key] = value
						end
						
						unless offset == parameters_string.length
							raise ParseError, "Invalid media range parameters: #{parameters_string[offset..].inspect}"
						end
						
						if (type.include?("*") && type != "*") || (subtype.include?("*") && subtype != "*") || (type == "*" && subtype != "*")
							raise ParseError, "Invalid wildcards in media range: #{type}/#{subtype}"
						end
						
						return MediaRange.new(type, subtype, parameters)
					else
						raise ParseError, "Invalid media type: #{value.inspect}"
					end
				end
			end
		end
	end
end
