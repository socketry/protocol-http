# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require_relative 'split'

module Protocol
	module HTTP
		module Header
			# This implementation is not strictly correct according to the RFC-specified format.
			class ETags < Split
				def wildcard?
					self.include?('*')
				end
				
				def match?(etag)
					wildcard? || self.include?(etag)
				end
			end
		end
	end
end
