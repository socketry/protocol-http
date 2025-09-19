# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2024, by Earlopain.

module Protocol
	module HTTP
		module Header
			# Used for basic authorization.
			#
			# ~~~ ruby
			# headers.add('authorization', Authorization.basic("my_username", "my_password"))
			# ~~~
			#
			# TODO Support other authorization mechanisms, e.g. bearer token.
			class Authorization < String
				# Splits the header into the credentials.
				#
				# @returns [Tuple(String, String)] The username and password.
				def credentials
					self.split(/\s+/, 2)
				end
				
				# Generate a new basic authorization header, encoding the given username and password.
				#
				# @parameter username [String] The username.
				# @parameter password [String] The password.
				# @returns [Authorization] The basic authorization header.
				def self.basic(username, password)
					strict_base64_encoded = ["#{username}:#{password}"].pack("m0")
					
					self.new(
						"Basic #{strict_base64_encoded}"
					)
				end
				
				def self.trailer_forbidden?
					true
				end
			end
		end
	end
end
