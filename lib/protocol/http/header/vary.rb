# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "split"

module Protocol
	module HTTP
		module Header
			# Represents the `vary` header, which specifies the request headers a server considers when determining the response.
			#
			# The `vary` header is used in HTTP responses to indicate which request headers affect the selected response. It allows caches to differentiate stored responses based on specific request headers.
			class Vary < Split
				# Initializes a `Vary` header with already-parsed and normalized values.
				#
				# @parameter value [Array | Nil] an array of normalized (lowercase) header names, or `nil` for an empty header.
				def initialize(value = nil)
					if value.is_a?(Array)
						super(value.map(&:downcase))
					elsif value.is_a?(String)
						# Compatibility with the old constructor, prefer to use `parse` instead:
						super()
						self << value
					elsif value
						raise ArgumentError, "Invalid value: #{value.inspect}"
					end
				end
				
				# Adds one or more comma-separated values to the `vary` header from a raw wire-format string. The values are converted to lowercase for normalization.
				#
				# @parameter value [String] a raw wire-format value containing one or more values separated by commas.
				def << value
					super(value.downcase)
				end
			end
		end
	end
end

