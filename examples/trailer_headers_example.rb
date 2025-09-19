#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "../lib/protocol/http/headers"
require "digest"

# Example: Using various headers suitable for trailers
puts "HTTP Trailers - Suitable Headers Example"
puts "=" * 50

# Create a new headers collection
headers = Protocol::HTTP::Headers.new

# Add regular response headers
headers.add("content-type", "application/json")
headers.add("content-length", "2048")

# Enable trailers for headers that are calculated during response generation
headers.trailer!

puts "Regular Headers:"
headers.each do |key, value|
	next if headers.trailer? && headers.trailer.any? {|tk, _| tk == key}
	puts "  #{key}: #{value}"
end

puts "\nSimulating response generation and trailer calculation..."

# 1. Server-Timing - Performance metrics calculated during processing
puts "\n1. Server-Timing Header:"
server_timing = Protocol::HTTP::Header::ServerTiming.new
server_timing << "db;dur=45.2;desc=\"Database query\""
server_timing << "cache;dur=12.8;desc=\"Redis lookup\""
server_timing << "render;dur=23.5;desc=\"JSON serialization\""

headers.add("server-timing", server_timing.to_s)
puts "   Added: #{server_timing}"

# 2. Digest - Content integrity calculated after body generation
puts "\n2. Digest Header:"
response_body = '{"message": "Hello, World!", "timestamp": "2025-09-19T06:18:21Z"}'
sha256_digest = Digest::SHA256.base64digest(response_body)
md5_digest = Digest::MD5.hexdigest(response_body)

digest = Protocol::HTTP::Header::Digest.new
digest << "sha-256=#{sha256_digest}"
digest << "md5=#{md5_digest}"

headers.add("digest", digest.to_s)
puts "   Added: #{digest}"
puts "   Response body: #{response_body}"

# 3. Custom Application Header - Application-specific metadata
puts "\n3. Custom Application Header:"
headers.add("x-processing-stats", "requests=1250, cache_hits=892, errors=0")
puts "   Added: x-processing-stats=requests=1250, cache_hits=892, errors=0"

# 4. Date - Response completion timestamp
puts "\n4. Date Header:"
completion_time = Time.now
headers.add("date", completion_time.httpdate)
puts "   Added: #{completion_time.httpdate}"

# 5. ETag - Content-based entity tag (when calculated from response)
puts "\n5. ETag Header:"
etag_value = "\"#{Digest::SHA1.hexdigest(response_body)[0..15]}\""
headers.add("etag", etag_value)
puts "   Added: #{etag_value}"

puts "\nFinal Trailer Headers (sent after response body):"
puts "-" * 50
headers.trailer do |key, value|
	puts "  #{key}: #{value}"
end

puts "\nWhy These Headers Are Perfect for Trailers:"
puts "-" * 45
puts "• Server-Timing: Performance metrics collected during processing"
puts "• Digest: Content hashes calculated after body generation"
puts "• Custom Headers: Application-specific metadata generated during response"
puts "• Date: Completion timestamp when response finishes"
puts "• ETag: Content-based tags when derived from response body"

puts "\nBenefits of Using Trailers:"
puts "• No need to buffer entire response to calculate metadata"
puts "• Streaming-friendly - can start sending body immediately"
puts "• Perfect for large responses where metadata depends on content"
puts "• Maintains HTTP semantics while enabling efficient processing"

# Demonstrate header integration and parsing
puts "\nHeader Integration Examples:"
puts "-" * 30

# Show that these headers work normally in the main header section too
normal_headers = Protocol::HTTP::Headers.new
normal_headers.add("server-timing", "total;dur=150.5")
normal_headers.add("digest", "sha-256=abc123")
normal_headers.add("x-cache-status", "hit")

puts "Normal headers (not trailers):"
normal_headers.each do |key, value|
	puts "  #{key}: #{value}"
end

puts "\nParsing capabilities:"
parsed_digest = Protocol::HTTP::Header::Digest.new("sha-256=#{sha256_digest}, md5=#{md5_digest}")
entries = parsed_digest.entries
puts "• Parsed digest entries: #{entries.size}"
puts "• First algorithm: #{entries.first.algorithm}"
puts "• Algorithms: #{entries.map(&:algorithm).join(', ')}"

parsed_timing = Protocol::HTTP::Header::ServerTiming.new("db;dur=25.4, cache;dur=8.2;desc=\"Redis hit\"")
timing_metrics = parsed_timing.metrics
puts "• Parsed timing metrics: #{timing_metrics.size}"
puts "• First metric: #{timing_metrics.first.name} (#{timing_metrics.first.duration}ms)"
