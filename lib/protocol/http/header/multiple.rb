# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

module Protocol
	module HTTP
		module Header
			# Header value which is split by newline charaters (e.g. cookies).
			class Multiple < Array
				def initialize(value)
					super()
					
					self << value
				end
				
				def to_s
					join("\n")
				end
			end
		end
	end
end
