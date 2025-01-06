# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.
# Copyright, 2023, by Thomas Morgan.

require_relative "split"
require_relative "quoted_string"
require_relative "../error"

module Protocol
	module HTTP
		module Header
			# The `accept-charset` header represents a list of character sets that the client can accept.
			class AcceptCharset < Split
				ParseError = Class.new(Error)
				
				# https://tools.ietf.org/html/rfc7231#section-5.3.1
				QVALUE = /0(\.[0-9]{0,3})?|1(\.[0]{0,3})?/
				
				# https://tools.ietf.org/html/rfc7231#section-5.3.3
				CHARSETS = /\A(?<charset>#{TOKEN})(;q=(?<q>#{QVALUE}))?\z/
				
				Charset = Struct.new(:charset, :q) do
					def quality_factor
						(q || 1.0).to_f
					end
				end
				
				# Parse the `accept-charset` header value into a list of character sets.
				#
				# @returns [Array(Charset)] the list of character sets and their associated quality factors.
				def charsets
					self.map do |value|
						if match = value.match(CHARSETS)
							Charset.new(match[:charset], match[:q])
						else
							raise ParseError.new("Could not parse character set: #{value.inspect}")
						end
					end
				end
				
				# Sort the character sets by quality factor, with the highest quality factor first.
				#
				# @returns [Array(Charset)] the list of character sets sorted by quality factor.
				def sorted_charsets
					# We do this to get a stable sort:
					self.charsets.sort_by.with_index{|object, index| [-object.quality_factor, index]}
				end
			end
		end
	end
end
