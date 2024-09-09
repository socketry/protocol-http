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
				
				# Represents an output wrapper around a stream, that can invoke a fiber when `#read`` is called.
				#
				# This behaves a little bit like a generator or lazy enumerator, in that it can be used to generate chunks of data on demand.
				#
				# When closing the the output, the block is invoked one last time with `nil` to indicate the end of the stream.
				class Output
					def initialize(input, block)
						stream = Stream.new(input, self)
						
						@from = nil
						@to = Fiber.new do
							block.call(stream)
						rescue => error
							# Ignore.
						ensure
							@to = nil
							self.close(error)
						end
					end
					
					# Can be invoked by the block to write to the stream.
					def write(chunk)
						if from = @from
							@from = nil
							@to = Fiber.current
							
							from.transfer(chunk)
						else
							raise ClosedError, "Stream is not being read!"
						end
					end
					
					# Indicates that no further output will be generated.
					def close_write(error = nil)
						close(error)
					end
					
					# Can be invoked by the block to close the stream. Closing the output means that no more chunks will be generated.
					def close(error = nil)
						$stderr.puts "Closing from: #{@from}, to: #{@to}, error: #{error}"
						if from = @from
							# We are closing from within the output fiber, so we need to transfer back to `@from`:
							@from = nil
							@to = Fiber.current
							
							if error
								from.raise(error)
							else
								$stderr.puts "Transferring to #{from}...", from.backtrace
								from.transfer(nil)
							end
						elsif to = @to
							# We are closing from outside the output fiber, so we need to resume the fiber appropriately:
							@from = Fiber.current
							@to = nil
							
							if error
								# The fiber will be resumed from where it last called write, and we will raise the error there:
								to.raise(error)
							else
								begin
									# If we get here, it means we are closing the fiber from the outside, so we need to transfer control back to the fiber:
									to.transfer(nil)
								rescue Protocol::HTTP::Body::Streamable::ClosedError
									# If the fiber then tries to write to the stream, it will raise a ClosedError, and we will end up here. We can ignore it, as we are already closing the stream and don't care about further writes.
								end
							end
						end
					end
					
					def read
						raise RuntimeError, "Stream is already being read!" if @from
						
						if to = @to
							@from = Fiber.current
							@to = nil
							
							to.transfer
						else
							return nil
						end
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
				
				class Input
					def initialize(from = Fiber.current)
						@from = from
						@to = nil
					end
					
					def read
						if from = @from
							@from = nil
							@to = Fiber.current
							
							return from.transfer
						else
							raise ClosedError, "Stream is not being written!"
						end
					end
					
					def write(chunk)
						if to = @to
							@from = Fiber.current
							@to = nil
							
							to.transfer(chunk)
						else
							raise ClosedError, "Stream is not being read!"
						end
					end
					
					def close_write(error = nil)
						if to = @to
							@from = Fiber.current
							@to = nil
							
							if error
								to.raise(error)
							else
								to.transfer(nil)
							end
						end
					end
					
					def close(error = nil)
						close_write(error)
					end
					
					def stream(body)
						body&.each do |chunk|
							self.write(chunk)
						end
					end
				end
				
				# A deferred body has an extra `stream` method which can be used to stream data into the body, as the response body won't be available until the request has been sent.
				class DeferredBody < Body
					def initialize(block)
						super(block, Input.new)
					end
					
					# Stream the response body into the block's input.
					def stream(body)
						@input.stream(body)
					end
				end
			end
		end
	end
end
