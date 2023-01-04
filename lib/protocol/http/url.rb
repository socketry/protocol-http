# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.
# Copyright, 2022, by Herrick Fang.

module Protocol
	module HTTP
		module URL
			# Escapes a string using percent encoding.
			def self.escape(string, encoding = string.encoding)
				string.b.gsub(/([^a-zA-Z0-9_.\-]+)/) do |m|
					'%' + m.unpack('H2' * m.bytesize).join('%').upcase
				end.force_encoding(encoding)
			end
			
			# Unescapes a percent encoded string.
			def self.unescape(string, encoding = string.encoding)
				string.b.gsub(/%(\h\h)/) do |hex|
					Integer($1, 16).chr
				end.force_encoding(encoding)
			end
			
			# According to https://tools.ietf.org/html/rfc3986#section-3.3, we escape non-pchar.
			NON_PCHAR = /([^a-zA-Z0-9_\-\.~!$&'()*+,;=:@\/]+)/.freeze
			
			# Escapes non-path characters using percent encoding.
			def self.escape_path(path)
				encoding = path.encoding
				path.b.gsub(NON_PCHAR) do |m|
					'%' + m.unpack('H2' * m.bytesize).join('%').upcase
				end.force_encoding(encoding)
			end
			
			# Encodes a hash or array into a query string.
			def self.encode(value, prefix = nil)
				case value
				when Array
					return value.map {|v|
						self.encode(v, "#{prefix}[]")
					}.join("&")
				when Hash
					return value.map {|k, v|
						self.encode(v, prefix ? "#{prefix}[#{escape(k.to_s)}]" : escape(k.to_s))
					}.reject(&:empty?).join('&')
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
				string.split('&') do |assignment|
					key, value = assignment.split('=', 2)
					
					yield unescape(key), value.nil? ? value : unescape(value)
				end
			end
			
			def self.split(name)
				name.scan(/([^\[]+)|(?:\[(.*?)\])/).flatten!.compact!
			end
			
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
			
			# TODO use native C extension from `Trenni::Reference`.
			def self.decode(string, maximum = 8, symbolize_keys: false)
				parameters = {}
				
				self.scan(string) do |name, value|
					keys = self.split(name)
					
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
