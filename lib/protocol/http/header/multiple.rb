# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

module Protocol
	module HTTP
		module Header
			# Represents headers that can contain multiple distinct values separated by newline characters.
			#
			# This isn't a specific header but is used as a base for headers that store multiple values, such as cookies. The values are split and stored as an array internally, and serialized back to a newline-separated string when needed.
			class Multiple < Array
				# Initializes the multiple header with the given value. As the header key-value pair can only contain one value, the value given here is added to the internal array, and subsequent values can be added using the `<<` operator.
				#
				# @parameter value [String] the raw header value.
				def initialize(value)
					super()
					
					self << value
				end
				
				# Serializes the stored values into a newline-separated string.
				#
				# @returns [String] the serialized representation of the header values.
				def to_s
					join("\n")
				end
			end
		end
	end
end
