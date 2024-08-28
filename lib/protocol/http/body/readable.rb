# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2023, by Bruno Sutic.

module Protocol
	module HTTP
		module Body
			# An interface for reading data from a body.
			#
			# Typically, you'd override `#read` to return chunks of data.
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
				
				def rewindable?
					false
				end
				
				def rewind
					false
				end
				
				def length
					nil
				end
				
				# Read the next available chunk.
				# @returns [String | Nil] The chunk of data, or `nil` if the stream has finished.
				def read
					nil
				end
				
				# Should the internal mechanism prefer to use {call}?
				# @returns [Boolean]
				def stream?
					false
				end
				
				# Write the body to the given stream.
				def call(stream)
					while chunk = self.read
						stream.write(chunk)
					end
				ensure
					stream.close
				end
				
				# Read all remaining chunks into a buffered body and close the underlying input.
				# @returns [Buffered] The buffered body.
				def finish
					# Internally, this invokes `self.each` which then invokes `self.close`.
					Buffered.read(self)
				end
				
				# Enumerate all chunks until finished, then invoke `#close`.
				#
				# @yields {|chunk| ...} The block to call with each chunk of data.
				# 	@parameter chunk [String | Nil] The chunk of data, or `nil` if the stream has finished.
				def each
					return to_enum(:each) unless block_given?
					
					begin
						while chunk = self.read
							yield chunk
						end
					ensure
						self.close($!)
					end
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
