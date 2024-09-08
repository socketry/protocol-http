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
				# Close the stream immediately. After invoking this method, the stream should be considered closed, and all internal resources should be released.
				#
				# If an error occured while handling the output, it can be passed as an argument. This may be propagated to the client, for example the client may be informed that the stream was not fully read correctly.
				#
				# Invoking `#read` after `#close` will return `nil`.
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
				
				def stream?
					false
				end
				
				# Invoke the body with the given stream.
				#
				# The default implementation simply writes each chunk to the stream. If the body is not ready, it will be flushed after each chunk. Closes the stream when finished or if an error occurs.
				#
				# Write the body to the given stream.
				#
				# @parameter stream [IO | Object] An `IO`-like object that responds to `#read`, `#write` and `#flush`.
				# @returns [Boolean] Whether the ownership of the stream was transferred.
				def call(stream)
					self.each do |chunk|
						stream.write(chunk)
						
						# Flush the stream unless we are immediately expecting more data:
						unless self.ready?
							stream.flush
						end
					end
				ensure
					stream.close
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
						stream: self.stream?,
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
