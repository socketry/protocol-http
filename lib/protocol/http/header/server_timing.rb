# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "split"
require_relative "quoted_string"
require_relative "../error"

module Protocol
	module HTTP
		module Header
			# The `server-timing` header communicates performance metrics about the request-response cycle to the client.
			#
			# This header allows servers to send timing information about various server-side operations, which can be useful for performance monitoring and debugging. Each metric can include a name, optional duration, and optional description.
			#
			# ## Examples
			#
			# ```ruby
			# server_timing = ServerTiming.new("db;dur=53.2")
			# server_timing << "cache;dur=12.1;desc=\"Redis lookup\""
			# puts server_timing.to_s
			# # => "db;dur=53.2, cache;dur=12.1;desc=\"Redis lookup\""
			# ```
			class ServerTiming < Split
				ParseError = Class.new(Error)
				
				# https://www.w3.org/TR/server-timing/
				METRIC = /\A(?<name>[a-zA-Z0-9][a-zA-Z0-9_\-]*)(;(?<params>.*))?\z/
				PARAM = /(?<key>dur|desc)=(?<value>[^;,]+|"[^"]*")/
				
				# A single metric in the Server-Timing header.
				Metric = Struct.new(:name, :duration, :description) do
					# Create a new server timing metric.
					#
					# @parameter name [String] the name of the metric.
					# @parameter duration [Float | Nil] the duration in milliseconds.
					# @parameter description [String | Nil] the description of the metric.
					def initialize(name, duration = nil, description = nil)
						super(name, duration, description)
					end
					
					# Convert the metric to its string representation.
					#
					# @returns [String] the formatted metric string.
					def to_s
						result = name.dup
						result << ";dur=#{duration}" if duration
						result << ";desc=\"#{description}\"" if description
						result
					end
				end
				
				# Parse the `server-timing` header value into a list of metrics.
				#
				# @returns [Array(Metric)] the list of metrics with their names, durations, and descriptions.
				def metrics
					self.map do |value|
						if match = value.match(METRIC)
							name = match[:name]
							params = match[:params] || ""
							
							duration = nil
							description = nil
							
							params.scan(PARAM) do |key, param_value|
								case key
								when "dur"
									duration = param_value.to_f
								when "desc"
									# Remove quotes if present
									if param_value.start_with?('"') && param_value.end_with?('"')
										description = param_value[1..-2]
									else
										description = param_value
									end
								end
							end
							
							Metric.new(name, duration, description)
						else
							raise ParseError.new("Could not parse server timing metric: #{value.inspect}")
						end
					end
				end
				
				# Server-Timing headers are safe to use as trailers since they contain
				# performance metrics that are typically calculated during response generation.
				def self.trailer?
					true
				end
			end
		end
	end
end
