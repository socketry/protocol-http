# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require_relative 'wrapper'

require 'digest/sha2'

module Protocol
	module HTTP
		module Body
			# Invokes a callback once the body has finished reading.
			class Digestable < Wrapper
				def self.wrap(message, digest = Digest::SHA256.new, &block)
					if body = message&.body and !body.empty?
						message.body = self.new(message.body, digest, block)
					end
				end
				
				def initialize(body, digest = Digest::SHA256.new, callback = nil)
					super(body)
					
					@digest = digest
					@callback = callback
				end
				
				def digest
					@digest
				end
				
				def etag
					@digest.hexdigest.dump
				end
				
				def stream?
					false
				end
				
				def read
					if chunk = super
						@digest.update(chunk)
						
						return chunk
					else
						@callback&.call(self)
						
						return nil
					end
				end
			end
		end
	end
end
