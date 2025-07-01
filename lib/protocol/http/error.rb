# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

module Protocol
	module HTTP
		# A generic, HTTP protocol error.
		class Error < StandardError
		end
		
		# Represents a bad request error (as opposed to a server error).
		# This is used to indicate that the request was malformed or invalid.
		module BadRequest
		end
		
		# Raised when a singleton (e.g. `content-length`) header is duplicated in a request or response.
		class DuplicateHeaderError < Error
			include BadRequest
			
			# @parameter key [String] The header key that was duplicated.
			def initialize(key)
				super("Duplicate singleton header key: #{key.inspect}")
			end
			
			# @attribute [String] key The header key that was duplicated.
			attr :key
		end
	end
end
