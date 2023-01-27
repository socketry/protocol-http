# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require_relative 'readable'

module Protocol
	module HTTP
		module Body
			class Head < Readable
				def self.for(body)
					head = self.new(body.length)
					
					body.close
					
					return head
				end
				
				def initialize(length)
					@length = length
				end
				
				def empty?
					true
				end
				
				def ready?
					true
				end
				
				def length
					@length
				end
			end
		end
	end
end
