# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.
# Copyright, 2023, by Thomas Morgan.

require_relative 'split'

module Protocol
	module HTTP
		module Header
			class CacheControl < Split
				PRIVATE = 'private'
				PUBLIC = 'public'
				NO_CACHE = 'no-cache'
				NO_STORE = 'no-store'
				MAX_AGE = 'max-age'
				S_MAXAGE = 's-maxage'
				
				STATIC = 'static'
				DYNAMIC = 'dynamic'
				STREAMING = 'streaming'
				
				MUST_REVALIDATE = 'must-revalidate'
				PROXY_REVALIDATE = 'proxy-revalidate'
				
				def initialize(value = nil)
					super(value&.downcase)
				end
				
				def << value
					super(value.downcase)
				end
				
				def static?
					self.include?(STATIC)
				end
				
				def dynamic?
					self.include?(DYNAMIC)
				end
				
				def streaming?
					self.include?(STREAMING)
				end
				
				def private?
					self.include?(PRIVATE)
				end
				
				def public?
					self.include?(PUBLIC)
				end
				
				def no_cache?
					self.include?(NO_CACHE)
				end
				
				def no_store?
					self.include?(NO_STORE)
				end
				
				# Indicates that a response must not be used once it is stale.
				# See https://www.rfc-editor.org/rfc/rfc9111.html#name-must-revalidate
				def must_revalidate?
					self.include?(MUST_REVALIDATE)
				end
				
				# Like must-revalidate, but for shared caches only.
				# See https://www.rfc-editor.org/rfc/rfc9111.html#name-proxy-revalidate
				def proxy_revalidate?
					self.include?(PROXY_REVALIDATE)
				end
				
				# The maximum time, in seconds, a response should be considered fresh.
				# See https://www.rfc-editor.org/rfc/rfc9111.html#name-max-age-2
				def max_age
					find_integer_value(MAX_AGE)
				end
				
				# Like max-age, but for shared caches only, which should use it before
				# max-age when present.
				# See https://www.rfc-editor.org/rfc/rfc9111.html#name-s-maxage
				def s_maxage
					find_integer_value(S_MAXAGE)
				end
				
				private
				
				def find_integer_value(value_name)
					if value = self.find{|value| value.start_with?(value_name)}
						_, age = value.split('=', 2)
						
						if age =~ /\A[0-9]+\z/
							return Integer(age)
						end
					end
				end
			end
		end
	end
end
