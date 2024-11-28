# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require_relative "split"

module Protocol
	module HTTP
		module Header
			# Represents the `priority` header, used to indicate the relative importance of an HTTP request.
			#
			# The `priority` header allows clients to express their preference for how resources should be prioritized by the server. It can include directives like `urgency` to specify the importance of a request, and `progressive` to indicate whether a response can be delivered incrementally.
			class Priority < Split
				# Urgency levels as defined in RFC 9218:
				#
				# These levels indicate the relative importance of a request, helping servers and intermediaries allocate resources efficiently. Properly setting urgency can significantly improve user-perceived performance by prioritizing critical content and deferring less important tasks.
				module Urgency
					# `background` priority indicates a request that is not time-sensitive and can be processed with minimal impact to other tasks. It is ideal for requests like analytics or logging, which do not directly impact the user's current experience.
					BACKGROUND = "background"
					
					# `low` priority indicates a request that is important but not critical. It is suitable for content like non-blocking images, videos, or scripts that enhance the experience but do not affect core functionality.
					LOW = "low"
					
					# `normal` priority (default) indicates the standard priority for most requests. It is appropriate for content like text, CSS, or essential images that are necessary for the primary user experience but do not require urgent delivery.
					NORMAL = "normal"
					
					# `high` priority indicates the highest priority, used for requests that are essential and time-critical to the user experience. Examples include content above-the-fold on a webpage, critical API calls, or resources required for rendering.
					HIGH = "high"
				end
				
				# The `progressive` flag indicates that the response can be delivered incrementally (progressively) as data becomes available. This is particularly useful for large resources like images or video streams, where partial delivery improves the user experience by allowing content to render or play before the full response is received.
				PROGRESSIVE = "progressive"
				
				# Initialize the priority header with the given value.
				#
				# @parameter value [String | Nil] the value of the priority header, if any.
				def initialize(value = nil)
					super(value&.downcase)
				end
				
				# Add a value to the priority header.
				def << value
					super(value.downcase)
				end
				
				# Returns the urgency level if specified.
				#
				# @returns [String | Nil] the urgency level if specified, or `nil`.
				def urgency
					if value = self.find{|value| value.start_with?("urgency=")}
						_, level = value.split("=", 2)
						
						return level
					end
				end
				
				# @returns [Boolean] whether the request should be delivered progressively.
				def progressive?
					self.include?(PROGRESSIVE)
				end
			end
		end
	end
end
