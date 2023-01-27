# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

module Protocol
	module HTTP
		# All supported HTTP methods
		class Methods
			GET = 'GET'
			POST = 'POST'
			PUT = 'PUT'
			PATCH = 'PATCH'
			DELETE = 'DELETE'
			HEAD = 'HEAD'
			OPTIONS = 'OPTIONS'
			LINK = 'LINK'
			UNLINK = 'UNLINK'
			TRACE = 'TRACE'
			CONNECT = 'CONNECT'
			
			def self.valid?(name)
				const_defined?(name)
			rescue NameError
				# Ruby will raise an exception if the name is not valid for a constant.
				return false
			end
			
			def self.each
				constants.each do |name|
					yield name, const_get(name)
				end
			end
			
			# Use Methods.constants to get all constants.
			self.each do |name, value|
				define_method(name.downcase) do |location, headers = nil, body = nil|
					self.call(
						Request[value, location.to_s, Headers[headers], body]
					)
				end
			end
		end
	end
end
