# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative 'readable'

module Protocol
	module HTTP
		module Body
			class File < Readable
				BLOCK_SIZE = 4096
				MODE = ::File::RDONLY | ::File::BINARY
				
				def self.open(path, *arguments, **options)
					self.new(::File.open(path, MODE), *arguments, **options)
				end
				
				def initialize(file, range = nil, size: file.size, block_size: BLOCK_SIZE)
					@file = file
					
					@block_size = block_size
					
					if range
						@file.seek(range.min)
						@offset = range.min
						@length = @remaining = range.size
					else
						@offset = 0
						@length = @remaining = size
					end
				end
				
				def close(error = nil)
					@file.close
					@remaining = 0
					
					super
				end
				
				attr :file
				
				attr :offset
				attr :length
				
				def empty?
					@remaining == 0
				end
				
				def ready?
					true
				end
				
				def rewind
					@file.seek(@offset)
					@remaining = @length
				end
				
				def read
					if @remaining > 0
						amount = [@remaining, @block_size].min
						
						if chunk = @file.read(amount)
							@remaining -= chunk.bytesize
							
							return chunk
						end
					end
				end
				
				def stream?
					true
				end
				
				def call(stream)
					IO.copy_stream(@file, stream, @remaining)
				ensure
					stream.close
				end
				
				def join
					return "" if @remaining == 0
					
					buffer = @file.read(@remaining)
					
					@remaining = 0
					
					return buffer
				end
				
				def inspect
					"\#<#{self.class} file=#{@file.inspect} offset=#{@offset} remaining=#{@remaining}>"
				end
			end
		end
	end
end
