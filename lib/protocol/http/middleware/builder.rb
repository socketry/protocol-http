# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.

require_relative "../middleware"

module Protocol
	module HTTP
		class Middleware
			# A convenient interface for constructing middleware stacks.
			class Builder
				# Initialize the builder with the given default application.
				#
				# @parameter default_app [Object] The default application to use if no middleware is specified.
				def initialize(default_app = NotFound)
					@use = []
					@app = default_app
				end
				
				# Use the given middleware with the given arguments and options.
				#
				# @parameter middleware [Class | Object] The middleware class to use.
				# @parameter arguments [Array] The arguments to pass to the middleware constructor.
				# @parameter options [Hash] The options to pass to the middleware constructor.
				# @parameter block [Proc] The block to pass to the middleware constructor.
				def use(middleware, *arguments, **options, &block)
					@use << proc{|app| middleware.new(app, *arguments, **options, &block)}
				end
				
				# Specify the (default) middleware application to use.
				#
				# @parameter app [Middleware] The application to use if no middleware is able to handle the request.
				def run(app)
					@app = app
				end
				
				# Convert the builder to an application by chaining the middleware together.
				#
				# @returns [Middleware] The application.
				def to_app
					@use.reverse.inject(@app){|app, use| use.call(app)}
				end
			end
			
			# Build a middleware application using the given block.
			def self.build(&block)
				builder = Builder.new
				
				if block_given?
					if block.arity == 0
						builder.instance_exec(&block)
					else
						yield builder
					end
				end
				
				return builder.to_app
			end
		end
	end
end
