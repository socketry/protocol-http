# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2022, by Herrick Fang.

module Protocol
	module HTTP
		# Helpers for working with URLs.
		module URL
			# Escapes a string using percent encoding, e.g. `a b` -> `a%20b`.
			#
			# @parameter string [String] The string to escape.
			# @returns [String] The escaped string.
			def self.escape(string, encoding = string.encoding)
				string.b.gsub(/([^a-zA-Z0-9_.\-]+)/) do |m|
					"%" + m.unpack("H2" * m.bytesize).join("%").upcase
				end.force_encoding(encoding)
			end
			
			# Unescapes a percent encoded string, e.g. `a%20b` -> `a b`.
			#
			# @parameter string [String] The string to unescape.
			# @returns [String] The unescaped string.
			def self.unescape(string, encoding = string.encoding)
				string.b.gsub(/%(\h\h)/) do |hex|
					Integer($1, 16).chr
				end.force_encoding(encoding)
			end
			
			# Matches characters that are not allowed in a URI path segment. According to RFC 3986 Section 3.3 (https://tools.ietf.org/html/rfc3986#section-3.3), a valid path segment consists of "pchar" characters. This pattern identifies characters that must be percent-encoded when included in a URI path segment.
			NON_PATH_CHARACTER_PATTERN = /([^a-zA-Z0-9_\-\.~!$&'()*+,;=:@\/]+)/.freeze
			
			# Escapes non-path characters using percent encoding. In other words, this method escapes characters that are not allowed in a URI path segment. According to RFC 3986 Section 3.3 (https://tools.ietf.org/html/rfc3986#section-3.3), a valid path segment consists of "pchar" characters. This method percent-encodes characters that are not "pchar" characters.
			#
			# @parameter path [String] The path to escape.
			# @returns [String] The escaped path.
			def self.escape_path(path)
				encoding = path.encoding
				path.b.gsub(NON_PATH_CHARACTER_PATTERN) do |m|
					"%" + m.unpack("H2" * m.bytesize).join("%").upcase
				end.force_encoding(encoding)
			end
			
			# Encodes a hash or array into a query string. This method is used to encode query parameters in a URL. For example, `{"a" => 1, "b" => 2}` is encoded as `a=1&b=2`.
			#
			# @parameter value [Hash | Array | Nil] The value to encode.
			# @parameter prefix [String] The prefix to use for keys.
			def self.encode(value, prefix = nil)
				case value
				when Array
					return value.map {|v|
						self.encode(v, "#{prefix}[]")
					}.join("&")
				when Hash
					return value.map {|k, v|
						self.encode(v, prefix ? "#{prefix}[#{escape(k.to_s)}]" : escape(k.to_s))
					}.reject(&:empty?).join("&")
				when nil
					return prefix
				else
					raise ArgumentError, "value must be a Hash" if prefix.nil?
					
					return "#{prefix}=#{escape(value.to_s)}"
				end
			end
			
			# Scan a string for URL-encoded key/value pairs.
			# @yields {|key, value| ...}
			# 	@parameter key [String] The unescaped key.
			# 	@parameter value [String] The unescaped key.
			def self.scan(string)
				string.split("&") do |assignment|
					next if assignment.empty?
					
					key, value = assignment.split("=", 2)
					
					yield unescape(key), value.nil? ? value : unescape(value)
				end
			end
			
			# Split a key into parts, e.g. `a[b][c]` -> `["a", "b", "c"]`.
			#
			# @parameter name [String] The key to split.
			# @returns [Array(String)] The parts of the key.
			def self.split(name)
				name.scan(/([^\[]+)|(?:\[(.*?)\])/)&.tap do |parts|
					parts.flatten!
					parts.compact!
				end
			end
			
			# Assign a value to a nested hash.
			#
			# @parameter keys [Array(String)] The parts of the key.
			# @parameter value [Object] The value to assign.
			# @parameter parent [Hash] The parent hash.
			def self.assign(keys, value, parent)
				top, *middle = keys
				
				middle.each_with_index do |key, index|
					if key.nil? or key.empty?
						parent = (parent[top] ||= Array.new)
						top = parent.size
						
						if nested = middle[index+1] and last = parent.last
							top -= 1 unless last.include?(nested)
						end
					else
						parent = (parent[top] ||= Hash.new)
						top = key
					end
				end
				
				parent[top] = value
			end
			
			# Decode a URL-encoded query string into a hash.
			#
			# @parameter string [String] The query string to decode.
			# @parameter maximum [Integer] The maximum number of keys in a path.
			# @parameter symbolize_keys [Boolean] Whether to symbolize keys.
			# @returns [Hash] The decoded query string.
			def self.decode(string, maximum = 8, symbolize_keys: false)
				parameters = {}
				
				self.scan(string) do |name, value|
					keys = self.split(name)
					
					if keys.empty?
						raise ArgumentError, "Invalid key path: #{name.inspect}!"
					end
					
					if keys.size > maximum
						raise ArgumentError, "Key length exceeded limit!"
					end
					
					if symbolize_keys
						keys.collect!{|key| key.empty? ? nil : key.to_sym}
					end
					
					self.assign(keys, value, parameters)
				end
				
				return parameters
			end
		end
	end
end
