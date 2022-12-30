# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require_relative 'split'

module Protocol
	module HTTP
		module Header
			class Vary < Split
				def initialize(value)
					super(value.downcase)
				end
				
				def << value
					super(value.downcase)
				end
			end
		end
	end
end
