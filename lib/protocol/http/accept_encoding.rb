# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require_relative "middleware"

require_relative "body/buffered"
require_relative "body/inflate"

module Protocol
	module HTTP
		# A middleware that sets the accept-encoding header and decodes the response according to the content-encoding header.
		class AcceptEncoding < Middleware
			# The header used to request encodings.
			ACCEPT_ENCODING = "accept-encoding".freeze
			
			# The header used to specify encodings.
			CONTENT_ENCODING = "content-encoding".freeze
			
			# The default wrappers to use for decoding content.
			DEFAULT_WRAPPERS = {
				"gzip" => Body::Inflate.method(:for),
				
				# There is no point including this:
				# 'identity' => ->(body){body},
			}
			
			# Initialize the middleware with the given delegate and wrappers.
			#
			# @parameter delegate [Protocol::HTTP::Middleware] The delegate middleware.
			# @parameter wrappers [Hash] A hash of encoding names to wrapper functions.
			def initialize(delegate, wrappers = DEFAULT_WRAPPERS)
				super(delegate)
				
				@accept_encoding = wrappers.keys.join(", ")
				@wrappers = wrappers
			end
			
			# Set the accept-encoding header and decode the response body.
			#
			# @parameter request [Protocol::HTTP::Request] The request to modify.
			# @returns [Protocol::HTTP::Response] The response.
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
