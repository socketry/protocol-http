# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2024, by Samuel Williams.

require "time"

module Protocol
	module HTTP
		module Header
			class Date < String
				def << value
					replace(value)
				end
				
				def to_time
					::Time.parse(self)
				end
			end
		end
	end
end
