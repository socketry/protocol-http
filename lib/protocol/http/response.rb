# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

require_relative 'body/buffered'
require_relative 'body/reader'

module Protocol
	module HTTP
		class Response
			prepend Body::Reader
			
			def initialize(version = nil, status = 200, headers = Headers.new, body = nil, protocol = nil)
				@version = version
				@status = status
				@headers = headers
				@body = body
				@protocol = protocol
			end
			
			attr_accessor :version
			attr_accessor :status
			attr_accessor :headers
			attr_accessor :body
			attr_accessor :protocol
			
			def hijack?
				false
			end
			
			def continue?
				@status == 100
			end
			
			def success?
				@status and @status >= 200 && @status < 300
			end
			
			def partial?
				@status == 206
			end
			
			def redirection?
				@status and @status >= 300 && @status < 400
			end
			
			def not_modified?
				@status == 304
			end
			
			def preserve_method?
				@status == 307 || @status == 308
			end
			
			def failure?
				@status and @status >= 400 && @status < 600
			end
			
			def bad_request?
				@status == 400
			end
			
			def server_failure?
				@status == 500
			end
			
			def self.[](status, headers = nil, body = nil, protocol = nil)
				body = Body::Buffered.wrap(body)
				headers = ::Protocol::HTTP::Headers[headers]
				
				self.new(nil, status, headers, body, protocol)
			end
			
			def self.for_exception(exception)
				Response[500, Headers['content-type' => 'text/plain'], ["#{exception.class}: #{exception.message}"]]
			end
			
			def to_s
				"#{@status} #{@version}"
			end
			
			def to_ary
				return @status, @headers, @body
			end
		end
	end
end
