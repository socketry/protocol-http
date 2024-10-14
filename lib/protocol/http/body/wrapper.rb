# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "readable"

module Protocol
	module HTTP
		module Body
			# Wrapping body instance. Typically you'd override `#read`.
			class Wrapper < Readable
				# Wrap the body of the given message in a new instance of this class.
				#
				# @parameter message [Request | Response] the message to wrap.
				# @returns [Wrapper | nil] the wrapped body or nil if the body was nil.
				def self.wrap(message)
					if body = message.body
						message.body = self.new(body)
					end
				end
				
				def initialize(body)
					@body = body
				end
				
				# The wrapped body.
				attr :body
				
				def close(error = nil)
					@body.close(error)
					
					# It's a no-op:
					# super
				end
				
				def empty?
					@body.empty?
				end
				
				def ready?
					@body.ready?
				end
				
				def buffered
					@body.buffered
				end
				
				def rewind
					@body.rewind
				end
				
				def rewindable?
					@body.rewindable?
				end
				
				def length
					@body.length
				end
				
				# Read the next available chunk.
				def read
					@body.read
				end
				
				def discard
					@body.discard
				end
				
				def as_json(...)
					{
						class: self.class.name,
						body: @body&.as_json
					}
				end
				
				def to_json(...)
					as_json.to_json(...)
				end
				
				def inspect
					@body.inspect
				end
			end
		end
	end
end
