# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'zlib'

require_relative 'deflate'

module Protocol
	module HTTP
		module Body
			class Inflate < ZStream
				def self.for(body, encoding = GZIP)
					self.new(body, Zlib::Inflate.new(encoding))
				end
				
				def stream?
					false
				end
				
				def read
					return if @stream.finished?
					
					# The stream might have been closed while waiting for the chunk to come in.
					while chunk = super
						@input_length += chunk.bytesize
						
						# It's possible this triggers the stream to finish.
						chunk = @stream.inflate(chunk)
						
						break unless chunk&.empty?
					end
					
					if chunk
						@output_length += chunk.bytesize
					elsif !@stream.closed?
						chunk = @stream.finish
						@output_length += chunk.bytesize
					end
					
					if chunk.empty? and @stream.finished?
						return nil
					end
					
					return chunk
				end
			end
		end
	end
end
