# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative 'body/buffered'
require_relative 'body/reader'

require_relative 'headers'
require_relative 'methods'

module Protocol
	module HTTP
		class Request
			prepend Body::Reader
			
			def initialize(scheme = nil, authority = nil, method = nil, path = nil, version = nil, headers = Headers.new, body = nil, protocol = nil)
				@scheme = scheme
				@authority = authority
				@method = method
				@path = path
				@version = version
				@headers = headers
				@body = body
				@protocol = protocol
			end
			
			# The request scheme, usually one of "http" or "https".
			attr_accessor :scheme

			# The request authority, usually a hostname and port number.
			attr_accessor :authority

			# The request method, usually one of "GET", "HEAD", "POST", "PUT", "DELETE", "CONNECT" or "OPTIONS".
			attr_accessor :method

			# The request path, usually a path and query string.
			attr_accessor :path

			# The request version, usually "http/1.0", "http/1.1", "h2", or "h3".
			attr_accessor :version

			# The request headers, contains metadata associated with the request such as the user agent, accept (content type), accept-language, etc.
			attr_accessor :headers

			# The request body, an instance of Protocol::HTTP::Body::Readable or similar.
			attr_accessor :body

			# The request protocol, usually empty, but occasionally "websocket" or "webtransport", can be either single value `String` or multi-value `Array` of `String` instances. In HTTP/1, it is used to request a connection upgrade, and in HTTP/2 it is used to indicate a specfic protocol for the stream.
			attr_accessor :protocol
			
			# Send the request to the given connection.
			def call(connection)
				connection.call(self)
			end
			
			def head?
				@method == Methods::HEAD
			end
			
			def connect?
				@method == Methods::CONNECT
			end
			
			def self.[](method, path, headers = nil, body = nil)
				body = Body::Buffered.wrap(body)
				headers = ::Protocol::HTTP::Headers[headers]
				
				self.new(nil, nil, method, path, nil, headers, body)
			end
			
			def idempotent?
				@method != Methods::POST && (@body.nil? || @body.empty?)
			end
			
			def as_json(...)
				{
					scheme: @scheme,
					authority: @authority,
					method: @method,
					path: @path,
					version: @version,
					headers: @headers&.as_json,
					body: @body&.as_json,
					protocol: @protocol
				}
			end
			
			def to_json(...)
				as_json.to_json(...)
			end
			
			def to_s
				"#{@scheme}://#{@authority}: #{@method} #{@path} #{@version}"
			end
		end
	end
end
