# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2022, by Dan Olson.

module Protocol
	module HTTP
		module Body
			# General operations for interacting with a request or response body.
			module Reader
				# Read chunks from the body.
				# @yield [String] read chunks from the body.
				def each(&block)
					if @body
						@body.each(&block)
						@body = nil
					end
				end
				
				# Reads the entire request/response body.
				# @return [String] the entire body as a string.
				def read
					if @body
						buffer = @body.join
						@body = nil
						
						return buffer
					end
				end
				
				# Gracefully finish reading the body. This will buffer the remainder of the body.
				# @return [Buffered] buffers the entire body.
				def finish
					if @body
						body = @body.finish
						@body = nil
						
						return body
					end
				end
				
				# Write the body of the response to the given file path.
				def save(path, mode = ::File::WRONLY|::File::CREAT, **options)
					if @body
						::File.open(path, mode, **options) do |file|
							self.each do |chunk|
								file.write(chunk)
							end
						end
					end
				end
				
				# Close the connection as quickly as possible. Discards body. May close the underlying connection if necessary to terminate the stream.
				def close(error = nil)
					if @body
						@body.close(error)
						@body = nil
					end
				end
				
				# Whether there is a body?
				def body?
					@body and !@body.empty?
				end
			end
		end
	end
end
