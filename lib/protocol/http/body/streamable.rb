# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require_relative 'readable'
require_relative 'stream'

module Protocol
	module HTTP
		module Body
			# A body that invokes a block that can read and write to a stream.
			#
			# In some cases, it's advantageous to directly read and write to the underlying stream if possible. For example, HTTP/1 upgrade requests, WebSockets, and similar. To handle that case, response bodies can implement `stream?` and return `true`. When `stream?` returns true, the body **should** be consumed by calling `call(stream)`. Server implementations may choose to always invoke `call(stream)` if it's efficient to do so. Bodies that don't support it will fall back to using `#each`.
			#
			# When invoking `call(stream)`, the stream can be read from and written to, and closed. However, the stream is only guaranteed to be open for the duration of the `call(stream)` call. Once the method returns, the stream **should** be closed by the server.
			class Streamable < Readable
				class Closed < StandardError
				end
				
				def initialize(block, input = nil)
					@block = block
					@input = input
					@output = nil
				end
				
				# Closing a stream indicates we are no longer interested in reading from it.
				def close(error = nil)
					if @input
						@input.close
						@input = nil
					end
					
					if @output
						@output.close(error)
					end
				end
				
				attr :block
				
				class Output
					def initialize(input, block)
						stream = Stream.new(input, self)
						
						@from = nil
						
						@fiber = Fiber.new do |from|
							@from = from
							block.call(stream)
						rescue Closed
							# Ignore.
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
							raise RuntimeError, "Stream is not being read!"
						end
					end
					
					# Can be invoked by the block to close the stream.
					def close(error = nil)
						if from = @from
							@from = nil
							from.transfer(nil)
						elsif @fiber
							@fiber.raise(error || Closed)
						end
					end
					
					def read
						raise RuntimeError, "Stream is already being read!" if @from
						
						@fiber&.transfer(Fiber.current)
					end
				end
				
				# Invokes the block in a fiber which yields chunks when they are available.
				def read
					@output ||= Output.new(@input, @block)
					
					return @output.read
				end
				
				def stream?
					true
				end
				
				def call(stream)
					raise "Streaming body has already been read!" if @output
					
					@block.call(stream)
				rescue => error
					raise
				ensure
					self.close(error)
				end
			end
		end
	end
end
