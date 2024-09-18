# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require "zlib"

require_relative "deflate"

module Protocol
	module HTTP
		module Body
			class Inflate < ZStream
				def self.for(body, encoding = GZIP)
					self.new(body, Zlib::Inflate.new(encoding))
				end
				
				def read
					if stream = @stream
						# Read from the underlying stream and inflate it:
						while chunk = super
							@input_length += chunk.bytesize
							
							# It's possible this triggers the stream to finish.
							chunk = stream.inflate(chunk)
							
							break unless chunk&.empty?
						end
					
						if chunk
							@output_length += chunk.bytesize
						elsif !stream.closed?
							chunk = stream.finish
							@output_length += chunk.bytesize
						end
						
						# If the stream is finished, we need to close it and potentially return nil:
						if stream.finished?
							@stream = nil
							stream.close
							
							while super
								# There is data left in the stream, so we need to keep reading until it's all consumed.
							end
							
							if chunk.empty?
								return nil
							end
						end
						
						return chunk
					end
				end
			end
		end
	end
end
