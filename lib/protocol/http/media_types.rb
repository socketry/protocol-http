# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2024, by Samuel Williams.

module Protocol
	module HTTP
		class MediaTypes
			WILDCARD = "*/*".freeze
			
			def initialize
				@map = {}
			end
			
			def freeze
				return self if frozen?
				
				@map.freeze
				@map.each_value(&:freeze)
				
				return super
			end
			
			# Given a list of content types (e.g. from browser_preferred_content_types), return the best converter. Media types can be an array of MediaRange or String values.
			def for(media_ranges)
				media_ranges.each do |media_range|
					range_string = media_range.range_string
					
					if object = @map[range_string]
						return object
					end
				end
				
				return nil
			end
			
			def []= media_range, object
				@map[media_range] = object
			end
			
			def [] media_range
				@map[media_range]
			end
			
			# Add a converter to the collection. A converter can be anything that responds to #content_type. Objects will be considered in the order they are added, subsequent objects cannot override previously defined media types. `object` must respond to #split('/', 2) which should give the type and subtype.
			def << object
				media_range = object.media_range
				
				# We set the default if not specified already:
				@map[WILDCARD] = object if @map.empty?
				
				type = media_range.type
				if type != "*"
					@map["#{type}/*"] ||= object
					
					subtype = media_range.subtype
					if subtype != "*"
						@map["#{type}/#{subtype}"] ||= object
					end
				end
				
				return self
			end
		end
	end
end
