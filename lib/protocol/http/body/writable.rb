# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2026, by Samuel Williams.

require_relative "readable"

module Protocol
	module HTTP
		module Body
			# A dynamic body which you can write to and read from.
			class Writable < Readable
				# An error indicating that the body has been closed and no further writes are allowed.
				class Closed < StandardError
				end
				
				# Initialize the writable body.
				#
				# @parameter length [Integer] The length of the response body if known.
				# @parameter queue [Thread::Queue] Specify a different queue implementation, e.g. `Thread::SizedQueue` to enable back-pressure.
				def initialize(length = nil, queue: Thread::Queue.new)
					@length = length
					@queue = queue
					@mutex = Thread::Mutex.new
					@count = 0
					@error = nil
				end
				
				# @attribute [Integer] The length of the response body if known.
				attr :length
				
				# @attribute [Integer] The number of chunks written to the body.
				attr :count
				
				# Stop consuming the body and discard any unread chunks. Future writes will fail with the given error, or {Closed} if no error is given.
				#
				# @parameter error [Exception | Nil] The error that caused this body to be closed, if any.
				def close(error = nil)
					@mutex.synchronize do
						unless @queue.closed?
							@error = error
							@queue.close
						end
						
						@queue.clear
					end
					
					super
				end
				
				# Whether the body is closed for writing. Buffered chunks may still be read.
				#
				# @returns [Boolean] Whether the body is closed.
				def closed?
					@queue.closed?
				end
				
				# @returns [Boolean] Whether the body is ready to be read from, without blocking.
				def ready?
					!@queue.empty? || @queue.closed?
				end
				
				# Indicates whether the body is empty. This can occur if the body has been closed, or if the producer has invoked {close_write} and the reader has consumed all available chunks.
				#
				# @returns [Boolean] Whether the body is empty.
				def empty?
					@error.nil? && @queue.empty? && @queue.closed?
				end
				
				# Read the next available chunk.
				#
				# @returns [String | Nil] The next chunk, or `nil` if the body is finished.
				# @raises [Exception] If the body was closed due to an error.
				def read
					chunk = @queue.pop
					
					if chunk.nil? and @error
						raise @error
					end
					
					return chunk
				end
				
				# Write a single chunk to the body. Signal completion by calling {close_write}.
				#
				# @parameter chunk [String] The chunk to write.
				# @raises [Closed] If the body has been closed without error.
				# @raises [Exception] If the body has been closed due to an error.
				def write(chunk)
					@queue.push(chunk)
					@count += 1
				rescue ClosedQueueError
					raise(@error || Closed)
				end
				
				# Signal that no more data will be written to the body.
				#
				# @parameter error [Exception] The error that caused this body to be closed, if any.
				def close_write(error = nil)
					@mutex.synchronize do
						unless @queue.closed?
							@error = error
							@queue.close
						end
					end
				end
				
				# The output interface for writing chunks to the body.
				class Output
					# Initialize the output with the given writable body.
					#
					# @parameter writable [Writable] The writable body.
					def initialize(writable)
						@writable = writable
						@closed = false
					end
					
					# @returns [Boolean] Whether the output is closed for writing only.
					def closed?
						@closed || @writable.closed?
					end
					
					# Write a chunk to the body.
					def write(chunk)
						@writable.write(chunk)
					end
					
					alias << write
					
					# Close the output stream.
					#
					# If an error is given, it will be raised by the reader after all buffered chunks have been consumed.
					#
					# @parameter error [Exception | Nil] The error that caused this stream to be closed, if any.
					def close(error = nil)
						@closed = true
						@writable.close_write(error)
					end
				end
				
				# Create an output wrapper which can be used to write chunks to the body.
				#
				# If a block is given, and the block raises an error, the reader will receive all buffered chunks followed by that error.
				#
				# @yields {|output| ...} if a block is given.
				# 	@parameter output [Output] The output wrapper.
				# @returns [Output] The output wrapper.
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
				
				# Inspect the body.
				#
				# @returns [String] A string representation of the body.
				def inspect
					if @error
						"#<#{self.class} #{@count} chunks written, #{status}, error=#{@error}>"
					else
						"#<#{self.class} #{@count} chunks written, #{status}>"
					end
				end
				
				private
				
				# @returns [String] A string representation of the body's status.
				def status
					if @queue.empty?
						if @queue.closed?
							"closed"
						else
							"waiting"
						end
					else
						if @queue.closed?
							"closing"
						else
							"ready"
						end
					end
				end
			end
		end
	end
end
