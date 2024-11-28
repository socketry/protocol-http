# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require_relative "split"

module Protocol
	module HTTP
		module Header
			# Represents the `priority` header, used to indicate the relative importance of an HTTP request.
			#
			# The `priority` header allows clients to express their preference for how resources should be prioritized by the server. It supports directives like `u=` to specify the urgency level of a request, and `i` to indicate whether a response can be delivered incrementally. The urgency levels range from 0 (highest priority) to 7 (lowest priority), while the `i` directive is a boolean flag.
			class Priority < Split
				# Initialize the priority header with the given value.
				#
				# @parameter value [String | Nil] the value of the priority header, if any. The value should be a comma-separated string of directives.
				def initialize(value = nil)
					super(value&.downcase)
				end
				
				# Add a value to the priority header.
				#
				# @parameter value [String] the directive to add to the header.
				def << value
					super(value.downcase)
				end
				
				# The default urgency level if not specified.
				DEFAULT_URGENCY = 3
				
				# Returns the urgency level if specified. 0 is the highest priority, and 7 is the lowest.
				#
				# @returns [Integer | Nil] the urgency level if specified, or `nil` if not present.
				def urgency(default = DEFAULT_URGENCY)
					if value = self.find { |value| value.start_with?("u=") }
						_, level = value.split("=", 2)
						return level.to_i
					end
					
					return default
				end
				
				# Checks if the response should be delivered incrementally.
				#
				# The `i` directive, when present, indicates that the response can be delivered incrementally as data becomes available.
				#
				# @returns [Boolean] whether the request should be delivered incrementally.
				def incremental?
					self.include?("i")
				end
			end
		end
	end
end
