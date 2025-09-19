# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "split"

module Protocol
	module HTTP
		module Header
			# The `transfer-encoding` header indicates the encoding transformations that have been applied to the message body.
			#
			# The `transfer-encoding` header is used to specify the form of encoding used to safely transfer the message body between the sender and receiver.
			class TransferEncoding < Split
				# The `chunked` transfer encoding allows a server to send data of unknown length by breaking it into chunks.
				CHUNKED = "chunked"
				
				# The `gzip` transfer encoding compresses the message body using the gzip algorithm.
				GZIP = "gzip"
				
				# The `deflate` transfer encoding compresses the message body using the deflate algorithm.
				DEFLATE = "deflate"
				
				# The `compress` transfer encoding compresses the message body using the compress algorithm.
				COMPRESS = "compress"
				
				# The `identity` transfer encoding indicates no transformation has been applied.
				IDENTITY = "identity"
				
				# Initializes the transfer encoding header with the given value. The value is split into distinct entries and converted to lowercase for normalization.
				#
				# @parameter value [String | Nil] the raw header value containing transfer encodings separated by commas.
				def initialize(value = nil)
					super(value&.downcase)
				end
				
				# Adds one or more comma-separated values to the transfer encoding header. The values are converted to lowercase for normalization.
				#
				# @parameter value [String] the value or values to add, separated by commas.
				def << value
					super(value.downcase)
				end
				
				# @returns [Boolean] whether the `chunked` encoding is present.
				def chunked?
					self.include?(CHUNKED)
				end
				
				# @returns [Boolean] whether the `gzip` encoding is present.
				def gzip?
					self.include?(GZIP)
				end
				
				# @returns [Boolean] whether the `deflate` encoding is present.
				def deflate?
					self.include?(DEFLATE)
				end
				
				# @returns [Boolean] whether the `compress` encoding is present.
				def compress?
					self.include?(COMPRESS)
				end
				
				# @returns [Boolean] whether the `identity` encoding is present.
				def identity?
					self.include?(IDENTITY)
				end
				
				def self.trailer_forbidden?
					true
				end
			end
		end
	end
end
