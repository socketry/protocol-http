# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.
# Copyright, 2023, by Thomas Morgan.

require_relative "split"

module Protocol
	module HTTP
		module Header
			class ETags < Split
				def wildcard?
					self.include?("*")
				end
				
				# This implementation is not strictly correct according to the RFC-specified format.
				def match?(etag)
					wildcard? || self.include?(etag)
				end
				
				# Useful with If-Match
				def strong_match?(etag)
					wildcard? || (!weak_tag?(etag) && self.include?(etag))
				end
				
				# Useful with If-None-Match
				def weak_match?(etag)
					wildcard? || self.include?(etag) || self.include?(opposite_tag(etag))
				end
				
				private
			
				def opposite_tag(etag)
					weak_tag?(etag) ? etag[2..-1] : "W/#{etag}"
				end
				
				def weak_tag?(tag)
					tag&.start_with? "W/"
				end
			end
		end
	end
end
