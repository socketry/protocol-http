# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative 'wrapper'

require 'zlib'

module Protocol
	module HTTP
		module Body
			class ZStream < Wrapper
				DEFAULT_LEVEL = 7
				
				DEFLATE = -Zlib::MAX_WBITS
				GZIP =  Zlib::MAX_WBITS | 16
				
				ENCODINGS = {
					'deflate' => DEFLATE,
					'gzip' => GZIP,
				}
				
				def initialize(body, stream)
					super(body)
					
					@stream = stream
					
					@input_length = 0
					@output_length = 0
				end
				
				def close(error = nil)
					@stream.close unless @stream.closed?
					
					super
				end
				
				def length
					# We don't know the length of the output until after it's been compressed.
					nil
				end
				
				attr :input_length
				attr :output_length
				
				def ratio
					if @input_length != 0
						@output_length.to_f / @input_length.to_f
					else
						1.0
					end
				end
				
				def inspect
					"#{super} | \#<#{self.class} #{(ratio*100).round(2)}%>"
				end
			end
			
			class Deflate < ZStream
				def self.for(body, window_size = GZIP, level = DEFAULT_LEVEL)
					self.new(body, Zlib::Deflate.new(level, window_size))
				end
				
				def read
					return if @stream.finished?
					
					# The stream might have been closed while waiting for the chunk to come in.
					if chunk = super
						@input_length += chunk.bytesize
						
						chunk = @stream.deflate(chunk, Zlib::SYNC_FLUSH)
						
						@output_length += chunk.bytesize
						
						return chunk
					elsif !@stream.closed?
						chunk = @stream.finish
						
						@output_length += chunk.bytesize
						
						return chunk.empty? ? nil : chunk
					end
				end
			end
		end
	end
end
