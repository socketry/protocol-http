# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

require 'base64'

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
					encoded = "#{username}:#{password}"
					
					self.new(
						"Basic #{Base64.strict_encode64(encoded)}"
					)
				end
			end
		end
	end
end
