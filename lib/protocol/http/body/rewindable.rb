# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative 'wrapper'
require_relative 'buffered'

module Protocol
	module HTTP
		module Body
			# A body which buffers all it's contents as it is `#read`.
			class Rewindable < Wrapper
				def self.wrap(message)
					if body = message.body
						if body.rewindable?
							body
						else
							message.body = self.new(body)
						end
					end
				end
				
				def initialize(body)
					super(body)
					
					@chunks = []
					@index = 0
				end
				
				def empty?
					(@index >= @chunks.size) && super
				end
				
				def ready?
					(@index < @chunks.size) || super
				end
				
				# A rewindable body wraps some other body. Convert it to a buffered body. The buffered body will share the same chunks as the rewindable body.
				#
				# @returns [Buffered] the buffered body. 
				def buffered
					Buffered.new(@chunks)
				end
				
				def stream?
					false
				end
				
				def read
					if @index < @chunks.size
						chunk = @chunks[@index]
						@index += 1
					else
						if chunk = super
							@chunks << -chunk
							@index += 1
						end
					end
					
					# We dup them on the way out, so that if someone modifies the string, it won't modify the rewindability.
					return chunk
				end
				
				def rewind
					@index = 0
				end
				
				def rewindable?
					true
				end
				
				def inspect
					"\#<#{self.class} #{@index}/#{@chunks.size} chunks read>"
				end
			end
		end
	end
end
