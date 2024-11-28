# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require_relative "split"

module Protocol
	module HTTP
		module Header
			# Represents the `vary` header, which specifies the request headers a server considers when determining the response.
			#
			# The `vary` header is used in HTTP responses to indicate which request headers affect the selected response. It allows caches to differentiate stored responses based on specific request headers.
			class Vary < Split
				# Initializes a `Vary` header with the given value. The value is split into distinct entries and converted to lowercase for normalization.
				#
				# @parameter value [String] the raw header value containing request header names separated by commas.
				def initialize(value)
					super(value.downcase)
				end
				
				# Adds one or more comma-separated values to the `vary` header. The values are converted to lowercase for normalization.
				#
				# @parameter value [String] the value or values to add, separated by commas.
				def << value
					super(value.downcase)
				end
			end
		end
	end
end