# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "../middleware"

module Protocol
	module HTTP
		class Middleware
			class Builder
				def initialize(default_app = NotFound)
					@use = []
					@app = default_app
				end
				
				def use(middleware, *arguments, **options, &block)
					@use << proc {|app| middleware.new(app, *arguments, **options, &block)}
				end
				
				def run(app)
					@app = app
				end
				
				def to_app
					@use.reverse.inject(@app) {|app, use| use.call(app)}
				end
			end
			
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
