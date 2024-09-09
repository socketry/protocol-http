# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

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
					@length = length
					@queue = queue
					@count = 0
					@error = nil
				end
				
				def length
					@length
				end
				
				# Stop generating output; cause the next call to write to fail with the given error. Does not prevent existing chunks from being read. In other words, this indicates both that no more data will be or should be written to the body.
				def close(error = nil)
					@error ||= error
					
					@queue.clear
					@queue.close
					
					super
				end
				
				def closed?
					@queue.closed?
				end
				
				def ready?
					!@queue.empty? || @queue.closed?
				end
				
				# Has the producer called #finish and has the reader consumed the nil token?
				def empty?
					@queue.empty? && @queue.closed?
				end
				
				# Read the next available chunk.
				def read
					if @error
						raise @error
					end
					
					@queue.pop
				end
				
				# Write a single chunk to the body. Signal completion by calling `#finish`.
				def write(chunk)
					if @queue.closed?
						raise(@error || Closed)
					end
					
					@queue.push(chunk)
					@count += 1
				end
				
				def close_write(error = nil)
					@error ||= error
					@queue.close
				end
				
				class Output
					def initialize(writable)
						@writable = writable
						@closed = false
					end
					
					def closed?
						@closed || @writable.closed?
					end
					
					def write(chunk)
						@writable.write(chunk)
					end
					
					alias << write
					
					def close(error = nil)
						@closed = true
						
						if error
							@writable.close(error)
						else
							@writable.close_write
						end
					end
				end
				
				# Create an output wrapper which can be used to write chunks to the body.
				def output
					output = Output.new(self)
					
					unless block_given?
						return output
					end
					
					begin
						yield output
					rescue => error
						raise error
					ensure
						output.close(error)
					end
				end
				
				def inspect
					"\#<#{self.class} #{@count} chunks written, #{status}>"
				end
				
				private
				
				def status
					if @queue.empty?
						if @queue.closed?
							'closed'
						else
							'waiting'
						end
					else
						if @queue.closed?
							'closing'
						else
							'ready'
						end
					end
				end
			end
		end
	end
end
