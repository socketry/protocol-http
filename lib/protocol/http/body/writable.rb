# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require_relative 'readable'

module Protocol
	module HTTP
		module Body
			# A dynamic body which you can write to and read from.
			class Writable < Readable
				class Closed < StandardError
				end
				
				# @param [Integer] length The length of the response body if known.
				# @param [Async::Queue] queue Specify a different queue implementation, e.g. `Async::LimitedQueue.new(8)` to enable back-pressure streaming.
				def initialize(length = nil, queue: Thread::Queue.new)
					@queue = queue
					
					@length = length
					
					@count = 0
					
					@finished = false
					
					@closed = false
					@error = nil
				end
				
				def length
					@length
				end
				
				# Stop generating output; cause the next call to write to fail with the given error.
				def close(error = nil)
					unless @closed
						@queue.close
						
						@closed = true
						@error = error
					end
					
					super
				end
				
				def closed?
					@closed
				end
				
				def ready?
					!@queue.empty?
				end
				
				# Has the producer called #finish and has the reader consumed the nil token?
				def empty?
					@finished
				end
				
				# Read the next available chunk.
				def read
					return if @finished
					
					unless chunk = @queue.pop
						@finished = true
					end
					
					return chunk
				end
				
				# Write a single chunk to the body. Signal completion by calling `#finish`.
				def write(chunk)
					# If the reader breaks, the writer will break.
					# The inverse of this is less obvious (*)
					if @closed
						raise(@error || Closed)
					end
					
					@count += 1
					@queue.push(chunk)
				end
				
				alias << write
				
				def inspect
					"\#<#{self.class} #{@count} chunks written, #{status}>"
				end
				
				private
				
				def status
					if @finished
						'finished'
					elsif @closed
						'closing'
					else
						'waiting'
					end
				end
			end
		end
	end
end
