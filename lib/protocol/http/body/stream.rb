# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2023, by Genki Takiuchi.

require_relative 'buffered'

module Protocol
	module HTTP
		module Body
			# The input stream is an IO-like object which contains the raw HTTP POST data. When applicable, its external encoding must be “ASCII-8BIT” and it must be opened in binary mode, for Ruby 1.9 compatibility. The input stream must respond to gets, each, read and rewind.
			class Stream
				NEWLINE = "\n"
				
				def initialize(input = nil, output = Buffered.new)
					@input = input
					@output = output
					
					raise ArgumentError, "Non-writable output!" unless output.respond_to?(:write)
					
					# Will hold remaining data in `#read`.
					@buffer = nil
					@closed = false
					@closed_read = false
				end
				
				attr :input
				attr :output
				
				# This provides a read-only interface for data, which is surprisingly tricky to implement correctly.
				module Reader
					# Read data from the underlying stream.
					#
					# If given a non-negative length, it will read at most that many bytes from the stream. If the stream is at EOF, it will return nil.
					#
					# If the length is not given, it will read all data until EOF, or return an empty string if the stream is already at EOF.
					#
					# If buffer is given, then the read data will be placed into buffer instead of a newly created String object.
					#
					# @param length [Integer] the amount of data to read
					# @param buffer [String] the buffer which will receive the data
					# @return a buffer containing the data
					def read(length = nil, buffer = nil)
						return '' if length == 0
						
						buffer ||= String.new.force_encoding(Encoding::BINARY)
						
						# Take any previously buffered data and replace it into the given buffer.
						if @buffer
							buffer.replace(@buffer)
							@buffer = nil
						else
							buffer.clear
						end
						
						if length
							while buffer.bytesize < length and chunk = read_next
								buffer << chunk
							end
							
							# This ensures the subsequent `slice!` works correctly.
							buffer.force_encoding(Encoding::BINARY)
							
							# This will be at least one copy:
							@buffer = buffer.byteslice(length, buffer.bytesize)
							
							# This should be zero-copy:
							buffer.slice!(length, buffer.bytesize)
							
							if buffer.empty?
								return nil
							else
								return buffer
							end
						else
							while chunk = read_next
								buffer << chunk
							end
							
							return buffer
						end
					end
					
					# Read some bytes from the stream.
					#
					# If the length is given, at most length bytes will be read. Otherwise, one chunk of data from the underlying stream will be read.
					#
					# Will avoid reading from the underlying stream if there is buffered data available.
					#
					# @parameter length [Integer] The maximum number of bytes to read.
					def read_partial(length = nil, buffer = nil)
						if @buffer
							if buffer
								buffer.replace(@buffer)
							else
								buffer = @buffer
							end
							@buffer = nil
						else
							if chunk = read_next
								if buffer
									buffer.replace(chunk)
								else
									buffer = chunk
								end
							else
								buffer&.clear
								buffer = nil
							end
						end
						
						if buffer and length
							if buffer.bytesize > length
								# This ensures the subsequent `slice!` works correctly.
								buffer.force_encoding(Encoding::BINARY)

								@buffer = buffer.byteslice(length, buffer.bytesize)
								buffer.slice!(length, buffer.bytesize)
							end
						end
						
						return buffer
					end
					
					# Similar to {read_partial} but raises an `EOFError` if the stream is at EOF.
					def readpartial(length, buffer = nil)
						read_partial(length, buffer) or raise EOFError, "End of file reached!"
					end
					
					# Read data from the stream without blocking if possible.
					def read_nonblock(length, buffer = nil, exception: nil)
						@buffer ||= read_next
						chunk = nil
						
						unless @buffer
							buffer&.clear
							return
						end
						
						if @buffer.bytesize > length
							chunk = @buffer.byteslice(0, length)
							@buffer = @buffer.byteslice(length, @buffer.bytesize)
						else
							chunk = @buffer
							@buffer = nil
						end
						
						if buffer
							buffer.replace(chunk)
						else
							buffer = chunk
						end
						
						return buffer
					end
					
					# Read data from the stream until encountering pattern.
					#
					# @parameter pattern [String] The pattern to match.
					# @parameter offset [Integer] The offset to start searching from.
					# @parameter chomp [Boolean] Whether to remove the pattern from the returned data.
					# @returns [String] The contents of the stream up until the pattern, which is consumed but not returned.
					def read_until(pattern, offset = 0, chomp: false)
						# We don't want to split on the pattern, so we subtract the size of the pattern.
						split_offset = pattern.bytesize - 1
						
						@buffer ||= read_next
						return nil if @buffer.nil?
						
						until index = @buffer.index(pattern, offset)
							offset = @buffer.bytesize - split_offset
							
							offset = 0 if offset < 0
							
							if chunk = read_next
								@buffer << chunk
							else
								return nil
							end
						end
						
						@buffer.freeze
						matched = @buffer.byteslice(0, index+(chomp ? 0 : pattern.bytesize))
						@buffer = @buffer.byteslice(index+pattern.bytesize, @buffer.bytesize)
						
						return matched
					end
					
					# Read a single line from the stream.
					#
					# @parameter separator [String] The line separator, defaults to `\n`.
					# @parameter *options [Hash] Additional options, passed to {read_until}.
					def gets(separator = NEWLINE, **options)
						read_until(separator, **options)
					end
				end
				
				include Reader
				
				# Write data to the underlying stream.
				#
				# @parameter buffer [String] The data to write.
				# @raises [IOError] If the stream is not writable.
				# @returns [Integer] The number of bytes written.
				def write(buffer)
					if @output
						@output.write(buffer)
						return buffer.bytesize
					else
						raise IOError, "Stream is not writable, output has been closed!"
					end
				end
				
				# Write data to the stream using {write}.
				#
				# Provided for compatibility with IO-like objects.
				#
				# @parameter buffer [String] The data to write.
				# @parameter exception [Boolean] Whether to raise an exception if the write would block, currently ignored.
				# @returns [Integer] The number of bytes written.
				def write_nonblock(buffer, exception: nil)
					write(buffer)
				end
				
				# Write data to the stream using {write}.
				def <<(buffer)
					write(buffer)
				end
				
				# Write lines to the stream.
				#
				# The current implementation buffers the lines and writes them in a single operation.
				#
				# @parameter arguments [Array(String)] The lines to write.
				# @parameter separator [String] The line separator, defaults to `\n`.
				def puts(*arguments, separator: NEWLINE)
					buffer = ::String.new
					
					arguments.each do |argument|
						buffer << argument << separator
					end
					
					write(buffer)
				end
				
				# Flush the output stream.
				#
				# This is currently a no-op.
				def flush
				end
				
				# Close the input body.
				def close_read(error = nil)
					if input = @input
						@input = nil
						@closed_read = true
						@buffer = nil
						
						input&.close(error)
					end
				end
				
				# Close the output body.
				def close_write(error = nil)
					if output = @output
						@output = nil
						
						# This is a compatibility hack to work around limitations in protocol-rack and can be removed when external tests are passing without it.
						if output.method(:close).arity == 1
							output.close(error)
						else
							output.close
						end
					end
				end
				
				# Close the input and output bodies.
				def close(error = nil)
					self.close_read
					self.close_write
					
					return nil
				ensure
					@closed = true
				end
				
				# Whether the stream has been closed.
				def closed?
					@closed
				end
				
				# Whether there are any output chunks remaining?
				def empty?
					@output.empty?
				end
				
				private
				
				def read_next
					if @input
						return @input.read
					elsif @closed_read
						raise IOError, "Stream is not readable, input has been closed!"
					end
				end
			end
		end
	end
end
