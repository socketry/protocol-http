# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative "methods"
require_relative "headers"
require_relative "request"
require_relative "response"

module Protocol
	module HTTP
		# The middleware interface provides a convenient wrapper for implementing HTTP middleware.
		#
		# A middleware instance generally needs to respond to two methods:
		#
		# - `call(request)` -> `response`
		# - `close()`
		#
		# The call method is called for each request. The close method is called when the server is shutting down.
		#
		# You do not need to use the Middleware class to implement middleware. You can implement the interface directly.
		class Middleware < Methods
			# Convert a block to a middleware delegate.
			def self.for(&block)
				def block.close
				end
				
				return self.new(block)
			end
			
			def initialize(delegate)
				@delegate = delegate
			end
			
			attr :delegate
			
			def close
				@delegate.close
			end
			
			def call(request)
				@delegate.call(request)
			end
			
			module Okay
				def self.close
				end
				
				def self.call(request)
					Response[200]
				end
			end
			
			module NotFound
				def self.close
				end
				
				def self.call(request)
					Response[404]
				end
			end
			
			module HelloWorld
				def self.close
				end
				
				def self.call(request)
					Response[200, Headers["content-type" => "text/plain"], ["Hello World!"]]
				end
			end
		end
	end
end
