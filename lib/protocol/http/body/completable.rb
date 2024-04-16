# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative 'wrapper'

module Protocol
	module HTTP
		module Body
			# Invokes a callback once the body has completed, either successfully or due to an error.
			class Completable < Wrapper
				def self.wrap(message, &block)
					if body = message&.body and !body.empty?
						message.body = self.new(message.body, block)
					else
						yield
					end
				end
				
				def initialize(body, callback)
					super(body)
					
					@callback = callback
				end
				
				def finish
					super.tap do
						if @callback
							@callback.call
							@callback = nil
						end
					end
				end
				
				def close(error = nil)
					super.tap do
						if @callback
							@callback.call(error)
							@callback = nil
						end
					end
				end
			end
		end
	end
end
