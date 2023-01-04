# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

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
				
				STATIC = 'static'
				DYNAMIC = 'dynamic'
				STREAMING = 'streaming'
				
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
				
				def max_age
					if value = self.find{|value| value.start_with?(MAX_AGE)}
						_, age = value.split('=', 2)
						
						return Integer(age)
					end
				end
			end
		end
	end
end
