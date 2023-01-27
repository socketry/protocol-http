# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2022, by Herrick Fang.

require_relative 'url'

module Protocol
	module HTTP
		# Represents an individual cookie key-value pair.
		class Cookie
			def initialize(name, value, directives)
				@name = name
				@value = value
				@directives = directives
			end
			
			attr :name
			attr :value
			attr :directives
			
			def encoded_name
				URL.escape(@name)
			end
			
			def encoded_value
				URL.escape(@value)
			end
			
			def to_s
				buffer = String.new.b
				
				buffer << encoded_name << '=' << encoded_value
				
				if @directives
					@directives.collect do |key, value|
						buffer << ';'
						
						case value
						when String
							buffer << key << '=' << value
						when TrueClass
							buffer << key
						end
					end
				end
				
				return buffer
			end
			
			def self.parse(string)
				head, *directives = string.split(/\s*;\s*/)
				
				key, value = head.split('=', 2)
				directives = self.parse_directives(directives)
				
				self.new(
					URL.unescape(key),
					URL.unescape(value),
					directives,
				)
			end
			
			def self.parse_directives(strings)
				strings.collect do |string|
					key, value = string.split('=', 2)
					[key, value || true]
				end.to_h
			end
		end
	end
end
