# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative 'multiple'
require_relative '../cookie'

module Protocol
	module HTTP
		module Header
			# The Cookie HTTP request header contains stored HTTP cookies previously sent by the server with the Set-Cookie header.
			class Cookie < Multiple
				def to_h
					cookies = self.collect do |string|
						HTTP::Cookie.parse(string)
					end
					
					cookies.map{|cookie| [cookie.name, cookie]}.to_h
				end
			end
			
			# The Set-Cookie HTTP response header sends cookies from the server to the user agent.
			class SetCookie < Cookie
			end
		end
	end
end
