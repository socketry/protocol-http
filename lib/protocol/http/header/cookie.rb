# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require_relative "multiple"
require_relative "../cookie"

module Protocol
	module HTTP
		module Header
			# The `cookie` header contains stored HTTP cookies previously sent by the server with the `set-cookie` header.
			#
			# It is used by clients to send key-value pairs representing stored cookies back to the server.
			class Cookie < Multiple
				# Parses the `cookie` header into a hash of cookie names and their corresponding cookie objects.
				#
				# @returns [Hash(String, HTTP::Cookie)] a hash where keys are cookie names and values are {HTTP::Cookie} objects.
				def to_h
					cookies = self.collect do |string|
						HTTP::Cookie.parse(string)
					end
					
					cookies.map{|cookie| [cookie.name, cookie]}.to_h
				end
				
				def self.trailer_forbidden?
					true
				end
			end
			
			# The `set-cookie` header sends cookies from the server to the user agent.
			#
			# It is used to store cookies on the client side, which are then sent back to the server in subsequent requests using the `cookie` header.
			class SetCookie < Cookie
			end
		end
	end
end
