# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

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
			
			# Whether the status is 100 (continue).
			def continue?
				@status == 100
			end
			
			# Whether the status is considered informational.
			def informational?
				@status and @status >= 100 && @status < 200
			end
			
			# Whether the status is considered final. Note that 101 is considered final.
			def final?
				# 101 is effectively a final status.
				@status and @status >= 200 || @status == 101
			end
			
			# Whether the status is 200 (ok).
			def ok?
				@status == 200
			end
			
			# Whether the status is considered successful.
			def success?
				@status and @status >= 200 && @status < 300
			end
			
			# Whether the status is 206 (partial content).
			def partial?
				@status == 206
			end
			
			# Whether the status is considered a redirection.
			def redirection?
				@status and @status >= 300 && @status < 400
			end
			
			# Whether the status is 304 (not modified).
			def not_modified?
				@status == 304
			end
			
			# Whether the status is 307 (temporary redirect) and should preserve the method of the request when following the redirect.
			def preserve_method?
				@status == 307 || @status == 308
			end
			
			# Whether the status is considered a failure.
			def failure?
				@status and @status >= 400 && @status < 600
			end
			
			# Whether the status is 400 (bad request).
			def bad_request?
				@status == 400
			end
			
			# Whether the status is 500 (internal server error).
			def internal_server_error?
				@status == 500
			end
			
			# @deprecated Use {#internal_server_error?} instead.
			alias server_failure? internal_server_error?
			
			def self.[](status, headers = nil, body = nil, protocol = nil)
				body = Body::Buffered.wrap(body)
				headers = ::Protocol::HTTP::Headers[headers]
				
				self.new(nil, status, headers, body, protocol)
			end
			
			def self.for_exception(exception)
				Response[500, Headers['content-type' => 'text/plain'], ["#{exception.class}: #{exception.message}"]]
			end
			
			def as_json
				{
					version: @version,
					status: @status,
					headers: @headers&.as_json,
					body: @body&.as_json,
					protocol: @protocol
				}
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
