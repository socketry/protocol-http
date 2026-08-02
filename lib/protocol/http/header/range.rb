# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "../error"

module Protocol
	module HTTP
		module Header
			# Represents a `range` request header.
			class Range
				ParseError = Class.new(Error)
				
				TOKEN = /[!#$%&'*+\-.0-9A-Z^_`a-z|~]+/
				HEADER = /\A(?<unit>#{TOKEN})=(?<ranges>.*)\z/
				BYTE_RANGE = /\A(?:(?<first>\d+)-(?<last>\d*)|-(?<suffix>\d+))\z/
				OTHER_RANGE = /\A[\x21-\x2B\x2D-\x7E]+\z/
				SEPARATOR = /\s*,\s*/
				
				# Represents one byte-range-spec or suffix-byte-range-spec.
				ByteRange = Struct.new(:first, :last) do
					# Parse one byte range.
					# @parameter value [String] The byte range to parse.
					# @returns [ByteRange] The parsed byte range.
					def self.parse(value)
						unless match = BYTE_RANGE.match(value)
							raise ParseError, "Invalid byte range: #{value.inspect}"
						end
						
						if suffix = match[:suffix]
							return self.new(nil, Integer(suffix))
						else
							first = Integer(match[:first])
							last = match[:last]
							last = last.empty? ? nil : Integer(last)
							
							if last && last < first
								raise ParseError, "Invalid byte range: #{value.inspect}"
							end
							
							return self.new(first, last)
						end
					end
					
					# Resolve this byte range against the selected representation size.
					# @parameter size [Integer] The size of the selected representation.
					# @returns [::Range | Nil] The resolved range, or `nil` when it is unsatisfiable.
					def resolve(size)
						if first
							if first < size
								return first..[last || size - 1, size - 1].min
							end
						elsif last > 0 && size > 0
							return [0, size - last].max..size - 1
						end
						
						return nil
					end
					
					# Convert this byte range to its wire representation.
					# @returns [String] The serialized byte range.
					def to_s
						if first
							"#{first}-#{last}"
						else
							"-#{last}"
						end
					end
				end
				
				# Parse a raw range header value.
				# @parameter value [String] The raw header value.
				# @returns [Range] The parsed range header.
				def self.parse(value)
					unless match = HEADER.match(value)
						raise ParseError, "Invalid range header: #{value.inspect}"
					end
					
					unit = match[:unit].downcase
					ranges = match[:ranges].split(SEPARATOR, -1)
					
					if ranges.empty? || ranges.any?(&:empty?)
						raise ParseError, "Invalid range set: #{match[:ranges].inspect}"
					end
					
					if unit == "bytes"
						ranges.map!{|range| ByteRange.parse(range)}
					elsif ranges.any?{|range| !OTHER_RANGE.match?(range)}
						raise ParseError, "Invalid range set: #{match[:ranges].inspect}"
					end
					
					return self.new(unit, ranges)
				end
				
				# Coerce a value into a range header.
				# @parameter value [Object] The value to coerce.
				# @returns [Range] The parsed range header.
				def self.coerce(value)
					self.parse(value.to_s)
				end
				
				# Initialize a range header.
				# @parameter unit [String] The range unit.
				# @parameter ranges [Array] The range specifiers.
				def initialize(unit, ranges)
					@unit = unit
					@ranges = ranges
				end
				
				# @attribute [String] The range unit.
				attr :unit
				
				# @attribute [Array] The range specifiers.
				attr :ranges
				
				# Whether this header contains byte ranges.
				# @returns [Boolean] Whether the range unit is `bytes`.
				def bytes?
					@unit == "bytes"
				end
				
				# Resolve all byte ranges against the selected representation size.
				# @parameter size [Integer] The size of the selected representation.
				# @returns [Array(::Range)] The satisfiable byte ranges.
				def resolve(size)
					unless bytes?
						raise ArgumentError, "Cannot resolve #{@unit.inspect} ranges as byte ranges!"
					end
					
					size = Integer(size)
					raise ArgumentError, "Size must not be negative!" if size < 0
					
					@ranges.filter_map{|range| range.resolve(size)}
				end
				
				# Combine another raw range header value with this one.
				# @parameter value [String] The raw range header value.
				def <<(value)
					other = self.class.parse(value)
					
					unless other.unit == @unit
						raise ParseError, "Cannot combine range units: #{@unit.inspect} and #{other.unit.inspect}"
					end
					
					@ranges.concat(other.ranges)
					
					return self
				end
				
				# Convert this header to its wire representation.
				# @returns [String] The serialized range header.
				def to_s
					"#{@unit}=#{@ranges.join(",")}"
				end
				
				# Whether this header is acceptable in HTTP trailers.
				# @returns [Boolean] `false`, as range headers apply to a selected representation.
				def self.trailer?
					false
				end
			end
		end
	end
end
