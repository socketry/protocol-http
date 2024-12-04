# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

module Protocol
	module HTTP
		module Header
			# Represents headers that can contain multiple distinct values separated by commas.
			#
			# This isn't a specific header  class is a utility for handling headers with comma-separated values, such as `accept`, `cache-control`, and other similar headers. The values are split and stored as an array internally, and serialized back to a comma-separated string when needed.
			class Split < Array
				# Regular expression used to split values on commas, with optional surrounding whitespace.
				COMMA = /\s*,\s*/
				
				# Initializes a `Split` header with the given value. If the value is provided, it is split into distinct entries and stored as an array.
				#
				# @parameter value [String | Nil] the raw header value containing multiple entries separated by commas, or `nil` for an empty header.
				def initialize(value = nil)
					if value
						super(value.split(COMMA))
					else
						super()
					end
				end
				
				# Adds one or more comma-separated values to the header.
				#
				# The input string is split into distinct entries and appended to the array.
				#
				# @parameter value [String] the value or values to add, separated by commas.
				def << value
					self.push(*value.split(COMMA))
				end
				
				# Serializes the stored values into a comma-separated string.
				#
				# @returns [String] the serialized representation of the header values.
				def to_s
					join(",")
				end
				
				protected
				
				def reverse_find(&block)
					reverse_each do |value|
						return value if block.call(value)
					end
					
					return nil
				end
			end
		end
	end
end
