# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2020, by Bryan Powell.

require_relative 'readable'

module Protocol
	module HTTP
		module Body
			# A body which buffers all it's contents.
			class Buffered < Readable
				# Tries to wrap an object in a {Buffered} instance.
				#
				# For compatibility, also accepts anything that behaves like an `Array(String)`.
				#
				# @parameter body [String | Array(String) | Readable | nil] the body to wrap.
				# @returns [Readable | nil] the wrapped body or nil if nil was given.
				def self.wrap(object)
					if object.is_a?(Readable)
						return object
					elsif object.is_a?(Array)
						return self.new(object)
					elsif object.is_a?(String)
						return self.new([object])
					elsif object
						return self.read(object)
					end
				end
				
				# Read the entire body into a buffered representation.
				#
				# @parameter body [Readable] the body to read.
				# @returns [Buffered] the buffered body.
				def self.read(body)
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
				
				# Ensure that future reads return nil, but allow for rewinding.
				def close(error = nil)
					@index = @chunks.length
				end
				
				def clear
					@chunks.clear
					@length = 0
					@index = 0
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
					return nil unless @chunks
					
					if chunk = @chunks[@index]
						@index += 1
						
						return chunk.dup
					end
				end
				
				def discard
					clear
				end
				
				def write(chunk)
					@chunks << chunk
				end
				
				def close_write(error)
					# Nothing to do.
				end
				
				def rewindable?
					@chunks != nil
				end
				
				def rewind
					return false unless @chunks
					
					@index = 0
					
					return true
				end
				
				def inspect
					if @chunks
						"\#<#{self.class} #{@chunks.size} chunks, #{self.length} bytes>"
					end
				end
			end
		end
	end
end
