# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2023, by Bruno Sutic.

module Protocol
	module HTTP
		module Body
			# Represents a readable input streams.
			#
			# Typically, you'd override `#read` to return chunks of data.
			#
			# I n general, you read chunks of data from a body until it is empty and returns `nil`. Upon reading `nil`, the body is considered consumed and should not be read from again.
			#
			# Reading can also fail, for example if the body represents a streaming upload, and the connection is lost. In this case, the body will raise some kind of error.
			#
			# If you don't want to read from a stream, and instead want to close it immediately, you can call `close` on the body. If the body is already completely consumed, `close` will do nothing, but if there is still data to be read, it will cause the underlying stream to be reset (and possibly closed).
			class Readable
				# Close the stream immediately.
				def close(error = nil)
				end
				
				# Optimistically determine whether read (may) return any data.
				# If this returns true, then calling read will definitely return nil.
				# If this returns false, then calling read may return nil.
				def empty?
					false
				end
				
				# Whether calling read will return a chunk of data without blocking.
				# We prefer pessimistic implementation, and thus default to `false`.
				# @return [Boolean]
				def ready?
					false
				end
				
				# Whether the stream can be rewound using {rewind}.
				def rewindable?
					false
				end
				
				# Rewind the stream to the beginning.
				# @returns [Boolean] Whether the stream was successfully rewound.
				def rewind
					false
				end
				
				# The total length of the body, if known.
				# @returns [Integer | Nil] The total length of the body, or `nil` if the length is unknown.
				def length
					nil
				end
				
				# Read the next available chunk.
				# @returns [String | Nil] The chunk of data, or `nil` if the stream has finished.
				# @raises [StandardError] If an error occurs while reading.
				def read
					nil
				end
				
				# Enumerate all chunks until finished, then invoke `#close`.
				#
				# Closes the stream when finished or if an error occurs.
				#
				# @yields {|chunk| ...} The block to call with each chunk of data.
				# 	@parameter chunk [String | Nil] The chunk of data, or `nil` if the stream has finished.
				def each
					return to_enum unless block_given?
					
					while chunk = self.read
						yield chunk
					end
				rescue => error
					raise
				ensure
					self.close(error)
				end
				
				# Read all remaining chunks into a single binary string using `#each`.
				#
				# @returns [String | Nil] The binary string containing all chunks of data, or `nil` if the stream has finished (or did not contain any data).
				def join
					buffer = String.new.force_encoding(Encoding::BINARY)
					
					self.each do |chunk|
						buffer << chunk
					end
					
					if buffer.empty?
						return nil
					else
						return buffer
					end
				end
				
				# Write the body to the given stream.
				#
				# In some cases, the stream may also be readable, such as when hijacking an HTTP/1 connection. In that case, it may be acceptable to read and write to the stream directly.
				#
				# If the stream is not ready, it will be flushed after each chunk. Closes the stream when finished or if an error occurs.
				#
				def call(stream)
					self.each do |chunk|
						stream.write(chunk)
						
						# Flush the stream unless we are immediately expecting more data:
						unless self.ready?
							stream.flush
						end
					end
				end
				
				# Read all remaining chunks into a buffered body and close the underlying input.
				#
				# @returns [Buffered] The buffered body.
				def finish
					# Internally, this invokes `self.each` which then invokes `self.close`.
					Buffered.read(self)
				end
				
				def as_json(...)
					{
						class: self.class.name,
						length: self.length,
						ready: self.ready?,
						empty: self.empty?
					}
				end
				
				def to_json(...)
					as_json.to_json(...)
				end
			end
		end
	end
end
