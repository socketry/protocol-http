# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative 'middleware'

require_relative 'body/buffered'
require_relative 'body/deflate'

module Protocol
	module HTTP
		# Encode a response according the the request's acceptable encodings.
		class ContentEncoding < Middleware
			DEFAULT_WRAPPERS = {
				'gzip' => Body::Deflate.method(:for)
			}
			
			DEFAULT_CONTENT_TYPES = %r{^(text/.*?)|(.*?/json)|(.*?/javascript)$}
			
			def initialize(app, content_types = DEFAULT_CONTENT_TYPES, wrappers = DEFAULT_WRAPPERS)
				super(app)
				
				@content_types = content_types
				@wrappers = wrappers
			end
			
			def call(request)
				response = super
				
				# Early exit if the response has already specified a content-encoding.
				return response if response.headers['content-encoding']
				
				# This is a very tricky issue, so we avoid it entirely.
				# https://lists.w3.org/Archives/Public/ietf-http-wg/2014JanMar/1179.html
				return response if response.partial?
				
				# Ensure that caches are aware we are varying the response based on the accept-encoding request header:
				response.headers.add('vary', 'accept-encoding')
				
				# TODO use http-accept and sort by priority
				if !response.body.empty? and accept_encoding = request.headers['accept-encoding']
					
					if content_type = response.headers['content-type'] and @content_types =~ content_type
						body = response.body
						
						accept_encoding.each do |name|
							if wrapper = @wrappers[name]
								response.headers['content-encoding'] = name
								
								body = wrapper.call(body)
								
								break
							end
						end
						
						response.body = body
					end
				end
				
				return response
			end
		end
	end
end
