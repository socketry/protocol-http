# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "readable"
require_relative "writable"

require_relative "stream"

module Protocol
	module HTTP
		module Body
			# A body that invokes a block that can read and write to a stream.
			#
			# In some cases, it's advantageous to directly read and write to the underlying stream if possible. For example, HTTP/1 upgrade requests, WebSockets, and similar. To handle that case, response bodies can implement `stream?` and return `true`. When `stream?` returns true, the body **should** be consumed by calling `call(stream)`. Server implementations may choose to always invoke `call(stream)` if it's efficient to do so. Bodies that don't support it will fall back to using `#each`.
			#
			# When invoking `call(stream)`, the stream can be read from and written to, and closed. However, the stream is only guaranteed to be open for the duration of the `call(stream)` call. Once the method returns, the stream **should** be closed by the server.
			module Streamable
				def self.request(&block)
					RequestBody.new(block)
				end
				
				def self.response(request, &block)
					ResponseBody.new(block, request.body)
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
					
					def close_input(error = nil)
						if input = @input
							@input = nil
							input.close(error)
						end
					end
					
					def close_output(error = nil)
						@output&.close(error)
					end
				end
				
				# A response body is used on the server side to generate the response body using a block.
				class ResponseBody < Body
					def close(error = nil)
						# Close will be invoked when all the output is written.
						self.close_output(error)
					end
				end
				
				# A request body is used on the client side to generate the request body using a block.
				#
				# As the response body isn't available until the request is sent, the response body must be {stream}ed into the request body.
				class RequestBody < Body
					def initialize(block)
						super(block, Writable.new)
					end
					
					def close(error = nil)
						# Close will be invoked when all the input is read.
						self.close_input(error)
					end
					
					# Stream the response body into the block's input.
					def stream(body)
						body&.each do |chunk|
							@input.write(chunk)
						end
					rescue => error
					ensure
						@input.close_write(error)
					end
				end
			end
		end
	end
end
