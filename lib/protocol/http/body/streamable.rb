# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative 'readable'
require_relative 'writable'

require_relative 'stream'

module Protocol
	module HTTP
		module Body
			# A body that invokes a block that can read and write to a stream.
			#
			# In some cases, it's advantageous to directly read and write to the underlying stream if possible. For example, HTTP/1 upgrade requests, WebSockets, and similar. To handle that case, response bodies can implement `stream?` and return `true`. When `stream?` returns true, the body **should** be consumed by calling `call(stream)`. Server implementations may choose to always invoke `call(stream)` if it's efficient to do so. Bodies that don't support it will fall back to using `#each`.
			#
			# When invoking `call(stream)`, the stream can be read from and written to, and closed. However, the stream is only guaranteed to be open for the duration of the `call(stream)` call. Once the method returns, the stream **should** be closed by the server.
			module Streamable
				# Raised when an operation is attempted on a closed stream.
				class ClosedError < StandardError
				end
				
				# Raised when a streaming body is consumed more than once.
				class ConsumedError < StandardError
				end
				
				# Single value queue that can be used to communicate between fibers.
				class Queue
					def self.consumer
						self.new(Fiber.current, nil)
					end
					
					def self.generator(&block)
						self.new(Fiber.new(&block), Fiber.current)
					end
					
					def initialize(generator, consumer)
						@generator = generator
						@consumer = consumer
						@closed = false
					end
					
					# The generator fiber can push values into the queue.
					def push(value)
						raise ClosedError, "Queue is closed!" if @closed
						
						if consumer = @consumer
							@consumer = nil
							@generator = Fiber.current
							
							consumer.transfer(value)
						else
							raise ClosedError, "Queue is not being popped!"
						end
					end
					
					# The consumer fiber can pop values from the queue.
					def pop
						return nil if @closed
						
						if generator = @generator
							@generator = nil
							@consumer = Fiber.current
							
							return generator.transfer
						else
							raise ClosedError, "Queue is not being pushed!"
						end
					end
					
					def close(error = nil)
						@closed = true
						
						if consumer = @consumer
							@consumer = nil
							
							if consumer.alive?
								@generator = Fiber.current
								if error
									consumer.raise(error)
								else
									consumer.transfer(nil)
								end
							end
						elsif generator = @generator
							@generator = nil
							@consumer = Fiber.current
							
							if error
								generator.raise(error)
							else
								generator.transfer(nil)
							end
						end
					end
				end
				
				def self.new(*arguments)
					if arguments.size == 1
						DeferredBody.new(*arguments)
					else
						Body.new(*arguments)
					end
				end
				
				def self.request(&block)
					DeferredBody.new(block)
				end
				
				def self.response(request, &block)
					Body.new(block, request.body)
				end
				
				class Input
					def initialize
						@queue = Queue.consumer
					end
					
					def read
						@queue.pop
					end
					
					def write(chunk)
						@queue.push(chunk)
					end
					
					def close_write(error = nil)
						close(error)
					end
					
					def close(error = nil)
						@queue.close(error)
					end
					
					def stream(body)
						body&.each do |chunk|
							$stderr.puts "Input stream chunk: #{chunk.inspect}"
							self.write(chunk)
						end
					ensure
						$stderr.puts "Input stream closed: #{$!}"
						self.close_write
					end
				end
				
				# Represents an output wrapper around a stream, that can invoke a fiber when `#read`` is called.
				#
				# This behaves a little bit like a generator or lazy enumerator, in that it can be used to generate chunks of data on demand.
				#
				# When closing the the output, the block is invoked one last time with `nil` to indicate the end of the stream.
				class Output
					def initialize(input, block)
						stream = Stream.new(input, self)
						
						@queue = Queue.generator do
							block.call(stream)
						end
					end
					
					attr :stream
					
					# Generator of the output can write chunks.
					def write(chunk)
						@queue.push(chunk)
					end
					
					# Indicates that no further output will be generated.
					def close_write(error = nil)
						close(error)
					end
					
					# Can be invoked by the block to close the stream. Closing the output means that no more chunks will be generated.
					def close(error = nil)
						@queue.close(error)
					end
					
					# Consumer of the output can read chunks.
					def read
						@queue.pop
					end
				end
				
				class Body < Readable
					def initialize(block, input = nil)
						@block = block
						@input = input
						@output = nil
					end
					
					attr :block
					
					def stream?
						true
					end
					
					# Invokes the block in a fiber which yields chunks when they are available.
					def read
						# We are reading chunk by chunk, allocate an output stream and execute the block to generate the chunks:
						if @output.nil?
							if @block.nil?
								raise ConsumedError, "Streaming body has already been consumed!"
							end
							
							@output = Output.new(@input, @block)
							@block = nil
						end
						
						@output.read
					end
					
					# Invoke the block with the given stream.
					#
					# The block can read and write to the stream, and must close the stream when finishing.
					def call(stream)
						if @block.nil?
							raise ConsumedError, "Streaming block has already been consumed!"
						end
						
						block = @block
						
						@input = @output = @block = nil
						
						# Ownership of the stream is passed into the block, in other words, the block is responsible for closing the stream.
						block.call(stream)
					rescue => error
						# If, for some reason, the block raises an error, we assume it may not have closed the stream, so we close it here:
						stream.close
						raise
					end
					
					# Closing a stream indicates we are no longer interested in reading from it.
					def close(error = nil)
						$stderr.puts "Closing output #{@output}..."
						if output = @output
							@output = nil
							# Closing the output here may take some time, as it may need to finish handling the stream:
							output.close(error)
						end
						
						$stderr.puts "Closing input #{@input}..."
						if input = @input
							@input = nil
							input.close(error)
						end
					end
				end
				
				# A deferred body has an extra `stream` method which can be used to stream data into the body, as the response body won't be available until the request has been sent.
				class DeferredBody < Body
					def initialize(block)
						super(block, Input.new)
					end
					
					# Closing a stream indicates we are no longer interested in reading from it.
					def close(error = nil)
					end
					
					# Stream the response body into the block's input.
					def stream(body)
						@input.stream(body)
						
						$stderr.puts "Closing output #{@output}..."
						if output = @output
							@output = nil
							# Closing the output here may take some time, as it may need to finish handling the stream:
							output.close(error)
						end
						
						$stderr.puts "Closing input #{@input}..."
						if input = @input
							@input = nil
							input.close(error)
						end
					end
				end
			end
		end
	end
end
