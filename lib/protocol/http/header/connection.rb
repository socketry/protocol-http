# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2024, by Thomas Morgan.

require_relative 'split'

module Protocol
	module HTTP
		module Header
			class Connection < Split
				KEEP_ALIVE = 'keep-alive'
				CLOSE = 'close'
				UPGRADE = 'upgrade'
				
				def initialize(value = nil)
					super(value&.downcase)
				end
				
				def << value
					super(value.downcase)
				end
				
				def keep_alive?
					self.include?(KEEP_ALIVE) && !close?
				end
				
				def close?
					self.include?(CLOSE)
				end
				
				def upgrade?
					self.include?(UPGRADE)
				end
			end
		end
	end
end
