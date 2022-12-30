# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

module Protocol
	module HTTP
		module Header
			# Header value which is split by commas.
			class Split < Array
				COMMA = /\s*,\s*/
				
				def initialize(value)
					super(value.split(COMMA))
				end
				
				def << value
					self.push(*value.split(COMMA))
				end
				
				def to_s
					join(", ")
				end
			end
		end
	end
end
