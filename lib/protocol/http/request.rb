# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative 'body/buffered'
require_relative 'body/reader'

require_relative 'headers'
require_relative 'methods'

module Protocol
	module HTTP
		# Represents an HTTP request which can be used both server and client-side.
		#
		# ~~~ ruby
		# require 'protocol/http'
		# 
		# # Long form:
		# Protocol::HTTP::Request.new("http", "example.com", "GET", "/index.html", "HTTP/1.1", Protocol::HTTP::Headers[["accept", "text/html"]])
		# 
		# # Short form:
		# Protocol::HTTP::Request["GET", "/index.html", {"accept" => "text/html"}]
		# ~~~
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
			
			# @attribute [String] the request scheme, usually `"http"` or `"https"`.
			attr_accessor :scheme
			
			# @attribute [String] the request authority, usually a hostname and port number, e.g. `"example.com:80"`.
			attr_accessor :authority
			
			# @attribute [String] the request method, usually one of `"GET"`, `"HEAD"`, `"POST"`, `"PUT"`, `"DELETE"`, `"CONNECT"` or `"OPTIONS"`, etc.
			attr_accessor :method
			
			# @attribute [String] the request path, usually a path and query string, e.g. `"/index.html"`, `"/search?q=hello"`, however it can be any [valid request target](https://www.rfc-editor.org/rfc/rfc9110#target.resource).
			attr_accessor :path
			
			# @attribute [String] the request version, usually `"http/1.0"`, `"http/1.1"`, `"h2"`, or `"h3"`.
			attr_accessor :version
			
			# @attribute [Headers] the request headers, usually containing metadata associated with the request such as the `"user-agent"`, `"accept"` (content type), `"accept-language"`, etc.
			attr_accessor :headers
			
			# @attribute [Body::Readable] the request body. It should only be read once (it may not be idempotent).
			attr_accessor :body

			# @attribute [String | Array(String) | Nil] the request protocol, usually empty, but occasionally `"websocket"` or `"webtransport"`. In HTTP/1, it is used to request a connection upgrade, and in HTTP/2 it is used to indicate a specfic protocol for the stream.
			attr_accessor :protocol
			
			# Send the request to the given connection.
			def call(connection)
				connection.call(self)
			end
			
			# Whether this is a HEAD request: no body is expected in the response.
			def head?
				@method == Methods::HEAD
			end
			
			# Whether this is a CONNECT request: typically used to establish a tunnel.
			def connect?
				@method == Methods::CONNECT
			end
			
			# A short-cut method which exposes the main request variables that you'd typically care about.
			#
			# @parameter method [String] The HTTP method, e.g. `"GET"`, `"POST"`, etc.
			# @parameter path [String] The path, e.g. `"/index.html"`, `"/search?q=hello"`, etc.
			# @parameter headers [Hash] The headers, e.g. `{"accept" => "text/html"}`, etc.
			# @parameter body [String | Array(String) | Body::Readable] The body, e.g. `"Hello, World!"`, etc. See {Body::Buffered.wrap} for more information about .
			def self.[](method, path, _headers = nil, _body = nil, scheme: nil, authority: nil, headers: _headers, body: _body, protocol: nil)
				body = Body::Buffered.wrap(body)
				headers = Headers[headers]
				
				self.new(scheme, authority, method, path, nil, headers, body, protocol)
			end
			
			# Whether the request can be replayed without side-effects.
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
