# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

module Protocol
	module HTTP
		# All supported HTTP methods, as outlined by <https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods>.
		class Methods
			# The GET method requests a representation of the specified resource. Requests using GET should only retrieve data.
			GET = 'GET'
			
			# The HEAD method asks for a response identical to a GET request, but without the response body.
			HEAD = 'HEAD'
			
			# The POST method submits an entity to the specified resource, often causing a change in state or side effects on the server.
			POST = 'POST'
			
			# The PUT method replaces all current representations of the target resource with the request payload.
			PUT = 'PUT'
			
			# The DELETE method deletes the specified resource.
			DELETE = 'DELETE'
			
			# The CONNECT method establishes a tunnel to the server identified by the target resource.
			CONNECT = 'CONNECT'
			
			# The OPTIONS method describes the communication options for the target resource.
			OPTIONS = 'OPTIONS'
			
			# The TRACE method performs a message loop-back test along the path to the target resource.
			TRACE = 'TRACE'
			
			# The PATCH method applies partial modifications to a resource.
			PATCH = 'PATCH'
			
			def self.valid?(name)
				const_defined?(name)
			rescue NameError
				# Ruby will raise an exception if the name is not valid for a constant.
				return false
			end
			
			# Enumerate all HTTP methods.
			# @yields {|name, value| ...}
			# 	@parameter name [Symbol] The name of the method, e.g. `:GET`.
			# 	@parameter value [String] The value of the method, e.g. `"GET"`.
			def self.each
				return to_enum(:each) unless block_given?
				
				constants.each do |name|
					yield name, const_get(name)
				end
			end
			
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
