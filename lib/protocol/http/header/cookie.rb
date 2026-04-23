# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.

require_relative "multiple"
require_relative "../cookie"

module Protocol
	module HTTP
		module Header
			# The `cookie` header contains stored HTTP cookies previously sent by the server with the `set-cookie` header.
			#
			# It is used by clients to send key-value pairs representing stored cookies back to the server.
			# Multiple cookies within a single `Cookie` header are joined with `"; "` per RFC 6265.
			class Cookie < Array
				# Parses a raw header value.
				#
				# @parameter value [String] a single raw header value.
				# @returns [Cookie] a new instance containing the parsed value.
				def self.parse(value)
					self.new([value])
				end

				# Coerces a value into a parsed header object.
				#
				# @parameter value [String | Array] the value to coerce.
				# @returns [Cookie] a parsed header object.
				def self.coerce(value)
					case value
					when Array
						self.new(value.map(&:to_s))
					else
						self.parse(value.to_s)
					end
				end

				# Initializes the cookie header with the given values.
				#
				# @parameter value [Array | Nil] an array of cookie strings, or `nil` for an empty header.
				def initialize(value = nil)
					super()

					if value
						self.concat(value)
					end
				end

				# Parses the `cookie` header into a hash of cookie names and their corresponding cookie objects.
				#
				# @returns [Hash(String, HTTP::Cookie)] a hash where keys are cookie names and values are {HTTP::Cookie} objects.
				def to_h
					cookies = self.collect do |string|
						HTTP::Cookie.parse(string)
					end

					cookies.map{|cookie| [cookie.name, cookie]}.to_h
				end

				# Serializes the `cookie` header by joining individual cookie strings with `"; "` per RFC 6265.
				def to_s
					join("; ")
				end

				# Whether this header is acceptable in HTTP trailers.
				# Cookie headers should not appear in trailers as they contain state information needed early in processing.
				# @returns [Boolean] `false`, as cookie headers are needed during initial request processing.
				def self.trailer?
					false
				end
			end

			# The `set-cookie` header sends cookies from the server to the user agent.
			#
			# Each `Set-Cookie` header must be a separate header field — they cannot be combined.
			# It is used to store cookies on the client side, which are then sent back to the server
			# in subsequent requests using the `cookie` header.
			class SetCookie < Multiple
				# Parses the `set-cookie` headers into a hash of cookie names and their corresponding cookie objects.
				#
				# @returns [Hash(String, HTTP::Cookie)] a hash where keys are cookie names and values are {HTTP::Cookie} objects.
				def to_h
					cookies = self.collect do |string|
						HTTP::Cookie.parse(string)
					end

					cookies.map{|cookie| [cookie.name, cookie]}.to_h
				end

				# Whether this header is acceptable in HTTP trailers.
				# @returns [Boolean] `false`, as set-cookie headers are needed during initial response processing.
				def self.trailer?
					false
				end
			end
		end
	end
end
