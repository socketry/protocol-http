# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.
# Copyright, 2020, by Bryan Powell.

require_relative 'readable'

module Protocol
	module HTTP
		module Body
			# A body which buffers all it's contents.
			class Buffered < Readable
				# Wraps an array into a buffered body.
				# @return [Readable, nil] the wrapped body or nil if nil was given.
				def self.wrap(body)
					if body.is_a?(Readable)
						return body
					elsif body.is_a?(Array)
						return self.new(body)
					elsif body.is_a?(String)
						return self.new([body])
					elsif body
						return self.for(body)
					end
				end
				
				def self.for(body)
					chunks = []
					
					body.each do |chunk|
						chunks << chunk
					end
					
					self.new(chunks)
				end
				
				def initialize(chunks = [], length = nil)
					@chunks = chunks
					@length = length
					
					@index = 0
				end
				
				attr :chunks
				
				def finish
					self
				end
				
				def length
					@length ||= @chunks.inject(0) {|sum, chunk| sum + chunk.bytesize}
				end
				
				def empty?
					@index >= @chunks.length
				end
				
				# A buffered response is always ready.
				def ready?
					true
				end
				
				def read
					if chunk = @chunks[@index]
						@index += 1
						
						return chunk.dup
					end
				end
				
				def write(chunk)
					@chunks << chunk
				end
				
				def rewind
					@index = 0
				end
				
				def inspect
					"\#<#{self.class} #{@chunks.size} chunks, #{self.length} bytes>"
				end
			end
		end
	end
end
