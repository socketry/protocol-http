# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.
# Copyright, 2025, by William T. Nelson.

require_relative "readable"

module Protocol
	module HTTP
		module Body
			# Represents a body suitable for HEAD requests, in other words, a body that is empty and has a known length.
			class Head < Readable
				# Create a head body for the given body, capturing its length and then closing it.
				def self.for(body)
					head = self.new(body.length)
					
					body.close
					
					return head
				end
				
				# Initialize the head body with the given length.
				#
				# @parameter length [Integer] the length of the body.
				def initialize(length)
					@length = length
				end
				
				# @returns [Boolean] the body is empty.
				def empty?
					true
				end
				
				# @returns [Boolean] the body is ready.
				def ready?
					true
				end
				
				# @returns [Integer] the length of the body, if known.
				def length
					@length
				end
			end
		end
	end
end
