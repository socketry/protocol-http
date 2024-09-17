# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative "middleware"

require_relative "body/buffered"
require_relative "body/inflate"

module Protocol
	module HTTP
		# Set a valid accept-encoding header and decode the response.
		class AcceptEncoding < Middleware
			ACCEPT_ENCODING = "accept-encoding".freeze
			CONTENT_ENCODING = "content-encoding".freeze
			
			DEFAULT_WRAPPERS = {
				"gzip" => Body::Inflate.method(:for),
				
				# There is no point including this:
				# 'identity' => ->(body){body},
			}
			
			def initialize(app, wrappers = DEFAULT_WRAPPERS)
				super(app)
				
				@accept_encoding = wrappers.keys.join(", ")
				@wrappers = wrappers
			end
			
			def call(request)
				request.headers[ACCEPT_ENCODING] = @accept_encoding
				
				response = super
				
				if body = response.body and !body.empty? and content_encoding = response.headers.delete(CONTENT_ENCODING)
					# We want to unwrap all encodings
					content_encoding.reverse_each do |name|
						if wrapper = @wrappers[name]
							body = wrapper.call(body)
						end
					end
					
					response.body = body
				end
				
				return response
			end
		end
	end
end
