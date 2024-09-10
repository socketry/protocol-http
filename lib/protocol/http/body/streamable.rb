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
				
				class Output
					def self.schedule(input, block)
						self.new(input, block).tap(&:schedule)
					end
					
					def initialize(input, block)
						@output = Writable.new
						@stream = Stream.new(input, @output)
						@block = block
					end
					
					def schedule
						@fiber ||= Fiber.schedule do
							@block.call(@stream)
						end
					end
					
					def read
						@output.read
					end
					
					def close(error = nil)
						@output.close_write(error)
					end
				end
				
				# Raised when a streaming body is consumed more than once.
				class ConsumedError < StandardError
				end
				
				class Body < Readable
					def initialize(block, input = nil)
						@block = block
						@input = input
						@output = nil
					end
					
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
							
							@output = Output.schedule(@input, @block)
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
						if output = @output
							@output = nil
							# Closing the output here may take some time, as it may need to finish handling the stream:
							output.close(error)
						end
						
						if input = @input
							@input = nil
							input.close(error)
						end
					end
				end
				
				# A deferred body has an extra `stream` method which can be used to stream data into the body, as the response body won't be available until the request has been sent.
				class DeferredBody < Body
					def initialize(block)
						super(block, Writable.new)
					end
					
					# Closing a stream indicates we are no longer interested in reading from it, but in this case that does not mean that the output block is finished generating data.
					def close(error = nil)
						if error
							super
						end
					end
					
					# Stream the response body into the block's input.
					def stream(body)
						body&.each do |chunk|
							@input.write(chunk)
						end
					rescue => error
						raise
					ensure
						@input.close_write(error)
					end
				end
			end
		end
	end
end
