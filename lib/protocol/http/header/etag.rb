# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

module Protocol
	module HTTP
		module Header
			class ETag < String
				def << value
					replace(value)
				end
				
				def weak?
					self.start_with?("W/")
				end
			end
		end
	end
end
