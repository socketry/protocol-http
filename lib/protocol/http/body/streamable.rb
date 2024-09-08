# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

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
				class ClosedError < StandardError
				end
				
				def self.new(*arguments)
					if arguments.size == 1
						DeferredBody.new(*arguments)
					else
						Body.new(*arguments)
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
						
						@from = nil
						
						@fiber = Fiber.new do |from|
							@from = from
							block.call(stream)
						ensure
							@fiber = nil
							
							# No more chunks will be generated:
							if from = @from
								@from = nil
								from.transfer(nil)
							end
						end
					end
					
					# Can be invoked by the block to write to the stream.
					def write(chunk)
						if from = @from
							@from = nil
							@from = from.transfer(chunk)
						else
							raise ClosedError, "Stream is not being read!"
						end
					end
					
					# Can be invoked by the block to close the stream. Closing the output means that no more chunks will be generated.
					def close(error = nil)
						if from = @from
							# We are closing from within the output fiber, so we need to transfer back to `@from`:
							@from = nil
							from.transfer(nil)
						elsif @fiber
							# We are closing from outside the output fiber, so we need to resume the fiber appropriately:
							@from = Fiber.current
							
							if error
								@fiber.raise(error)
							else
								@fiber.transfer(nil)
							end
						end
					end
					
					def read
						raise RuntimeError, "Stream is already being read!" if @from
						
						@fiber&.transfer(Fiber.current)
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
								raise "Streaming body has already been consumed!"
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
							raise "Streaming block has already been consumed!"
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
						$stderr.puts "Closing input: #{@input.inspect}"
						if input = @input
							@input = nil
							input.close(error)
						end
						
						if output = @output
							@output = nil
							output.close(error)
						end
					end
				end
				
				# A deferred body has an extra `stream` method which can be used to stream data into the body, as the response body won't be available until the request has been sent.
				class DeferredBody < Body
					def initialize(block)
						super(block, Writable.new)
						@finishing = false
					end
					
					def close(error = nil)
						return unless @finishing
						super
					end
					
					# Stream the response body into the block's input.
					def stream(input)
						input&.each do |chunk|
							@input&.write(chunk)
						end
					rescue => error
						raise
					ensure
						@finishing = true
						@input&.close
						
						self.close(error)
					end
				end
			end
		end
	end
end
