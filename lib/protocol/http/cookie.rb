# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2022, by Herrick Fang.

require_relative "url"

module Protocol
	module HTTP
		# Represents an individual cookie key-value pair.
		class Cookie
			# Initialize the cookie with the given name, value, and directives.
			#
			# @parameter name [String] The name of the cookiel, e.g. "session_id".
			# @parameter value [String] The value of the cookie, e.g. "1234".
			# @parameter directives [Hash] The directives of the cookie, e.g. `{"path" => "/"}`.
			def initialize(name, value, directives)
				@name = name
				@value = value
				@directives = directives
			end
			
			# @attribute [String] The name of the cookie.
			attr :name
			
			# @attribute [String] The value of the cookie.
			attr :value
			
			# @attribute [Hash] The directives of the cookie.
			attr :directives
			
			# Encode the name of the cookie.
			def encoded_name
				URL.escape(@name)
			end
			
			# Encode the value of the cookie.
			def encoded_value
				URL.escape(@value)
			end
			
			# Convert the cookie to a string.
			#
			# @returns [String] The string representation of the cookie.
			def to_s
				buffer = String.new.b
				
				buffer << encoded_name << "=" << encoded_value
				
				if @directives
					@directives.collect do |key, value|
						buffer << ";"
						
						case value
						when String
							buffer << key << "=" << value
						when TrueClass
							buffer << key
						end
					end
				end
				
				return buffer
			end
			
			# Parse a string into a cookie.
			#
			# @parameter string [String] The string to parse.
			# @returns [Cookie] The parsed cookie.
			def self.parse(string)
				head, *directives = string.split(/\s*;\s*/)
				
				key, value = head.split("=", 2)
				directives = self.parse_directives(directives)
				
				self.new(
					URL.unescape(key),
					URL.unescape(value),
					directives,
				)
			end
			
			# Parse a list of strings into a hash of directives.
			#
			# @parameter strings [Array(String)] The list of strings to parse.
			# @returns [Hash] The hash of directives.
			def self.parse_directives(strings)
				strings.collect do |string|
					key, value = string.split("=", 2)
					[key, value || true]
				end.to_h
			end
		end
	end
end
