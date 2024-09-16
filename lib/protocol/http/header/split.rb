# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

module Protocol
	module HTTP
		module Header
			# Header value which is split by commas.
			class Split < Array
				COMMA = /\s*,\s*/
				
				def initialize(value)
					if value && value.respond_to?(:split)
						super(value.split(COMMA))
					elsif value
						super([value])
					else
						super([])
					end
				end
				
				def << value
					self.push(*value.split(COMMA))
				end
				
				def to_s
					join(",")
				end
			end
		end
	end
end
