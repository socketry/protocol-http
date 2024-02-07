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
			class Authorization < String
				# Splits the header and 
				# @return [Tuple(String, String)]
				def credentials
					self.split(/\s+/, 2)
				end
				
				def self.basic(username, password)
					strict_base64_encoded = ["#{username}:#{password}"].pack('m0')
					
					self.new(
						"Basic #{strict_base64_encoded}"
					)
				end
			end
		end
	end
end
