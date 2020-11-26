# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

module Protocol
	module HTTP
		module Body
			# A generic base class for wrapping body instances. Typically you'd override `#read`.
			# The implementation assumes a sequential unbuffered stream of data.
			# 	def each -> yield(String | nil)
			# 	def read -> String | nil
			# 	def join -> String
			
			# 	def finish -> buffer the stream and close it.
			# 	def close(error = nil) -> close the stream immediately.
			# end
			class Readable
				# The consumer can call stop to signal that the stream output has terminated.
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
				
				def length
					nil
				end
				
				# Read the next available chunk.
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
				def finish
					# Internally, this invokes `self.each` which then invokes `self.close`.
					Buffered.for(self)
				end
				
				# Enumerate all chunks until finished, then invoke `#close`.
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
			end
		end
	end
end
