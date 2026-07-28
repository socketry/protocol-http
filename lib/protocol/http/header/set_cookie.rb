# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.

require_relative "multiple"
require_relative "../cookie"

module Protocol
	module HTTP
		module Header
			# The `set-cookie` header sends cookies from the server to the user agent.
			#
			# Each `Set-Cookie` header must be a separate header field — they cannot be combined.
			# It is used to store cookies on the client side, which are then sent back to the server
			# in subsequent requests using the `cookie` header.
			class SetCookie < Multiple
				# Parses the `set-cookie` headers into a hash of cookie names and their corresponding cookie objects.
				#
				# @returns [Hash(String, HTTP::Cookie)] a hash where keys are cookie names and values are {HTTP::Cookie} objects.
				def to_h
					cookies = self.collect do |string|
						HTTP::Cookie.parse(string)
					end
					
					cookies.map{|cookie| [cookie.name, cookie]}.to_h
				end
				
				# Whether this header is acceptable in HTTP trailers.
				# @returns [Boolean] `false`, as set-cookie headers are needed during initial response processing.
				def self.trailer?
					false
				end
			end
		end
	end
end
