# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require "protocol/http/accept_encoding"

describe Protocol::HTTP::AcceptEncoding do
	let(:delegate) do
		->(request) {
			Protocol::HTTP::Response[200, Protocol::HTTP::Headers["content-type" => "text/plain"], ["Hello World!"]]
		}
	end
	
	let(:middleware) { Protocol::HTTP::AcceptEncoding.new(delegate) }
	
	with "known encodings" do
		it "can decode gzip responses" do
			# Mock a response with gzip encoding
			gzip_delegate = ->(request) {
				Protocol::HTTP::Response[200, 
					Protocol::HTTP::Headers[
						"content-type" => "text/plain",
						"content-encoding" => "gzip"
					], 
					["Hello World!"]
				]
			}
			
			gzip_middleware = Protocol::HTTP::AcceptEncoding.new(gzip_delegate)
			request = Protocol::HTTP::Request["GET", "/"]
			response = gzip_middleware.call(request)
			
			expect(response.headers).not.to have_keys("content-encoding")
			expect(response.body).to be_a(Protocol::HTTP::Body::Inflate)
		end
	end
	
	with "unknown encodings" do
		it "preserves unknown content-encoding headers" do
			# Mock a response with brotli encoding (not in DEFAULT_WRAPPERS)
			br_delegate = ->(request) {
				Protocol::HTTP::Response[200, 
					Protocol::HTTP::Headers[
						"content-type" => "text/plain",
						"content-encoding" => "br"
					], 
					["Hello World!"]  # This would actually be brotli-encoded in reality
				]
			}
			
			br_middleware = Protocol::HTTP::AcceptEncoding.new(br_delegate)
			request = Protocol::HTTP::Request["GET", "/"]
			response = br_middleware.call(request)
			
			# The bug: this currently fails because content-encoding gets removed
			# when the middleware encounters an unknown encoding
			expect(response.headers).to have_keys("content-encoding")
			expect(response.headers["content-encoding"]).to be == ["br"]
			# The body should remain untouched since we can't decode it
			expect(response.body).not.to be_a(Protocol::HTTP::Body::Inflate)
		end
		
		it "preserves mixed known and unknown encodings" do
			# Mock a response with multiple encodings where some are unknown
			mixed_delegate = ->(request) {
				Protocol::HTTP::Response[200, 
					Protocol::HTTP::Headers[
						"content-type" => "text/plain",
						"content-encoding" => "gzip, br"  # gzip is known, br is unknown
					], 
					["Hello World!"]
				]
			}
			
			mixed_middleware = Protocol::HTTP::AcceptEncoding.new(mixed_delegate)
			request = Protocol::HTTP::Request["GET", "/"]
			response = mixed_middleware.call(request)
			
			# The bug: this currently fails because the entire content-encoding 
			# header gets removed when ANY unknown encoding is present
			expect(response.headers).to have_keys("content-encoding")
			expect(response.headers["content-encoding"]).to be == ["gzip", "br"]
			# The body should remain untouched since we can't decode the br part
			expect(response.body).not.to be_a(Protocol::HTTP::Body::Inflate)
		end
		
		it "handles case-insensitive encoding names" do
			# Mock a response with uppercase encoding name
			uppercase_delegate = ->(request) {
				Protocol::HTTP::Response[200, 
					Protocol::HTTP::Headers[
						"content-type" => "text/plain",
						"content-encoding" => "GZIP"
					], 
					["Hello World!"]
				]
			}
			
			uppercase_middleware = Protocol::HTTP::AcceptEncoding.new(uppercase_delegate)
			request = Protocol::HTTP::Request["GET", "/"]
			response = uppercase_middleware.call(request)
			
			# This might also be a bug - encoding names should be case-insensitive
			# but the current implementation uses exact string matching
			expect(response.headers).not.to have_keys("content-encoding")
			expect(response.body).to be_a(Protocol::HTTP::Body::Inflate)
		end
	end
	
	with "issue #86 - transparent proxy scenario" do
		it "preserves unknown content-encoding when acting as transparent proxy" do
			# This test simulates the exact scenario described in issue #86
			# where a transparent proxy fetches content with brotli encoding
			# but the AcceptEncoding middleware doesn't know about brotli
			
			# Mock upstream server that returns brotli-encoded content
			upstream_delegate = ->(request) {
				# Simulate a server responding with brotli encoding
				# when the request has accept-encoding: gzip
				expect(request.headers["accept-encoding"]).to be == ["gzip"]
				
				Protocol::HTTP::Response[200, 
					Protocol::HTTP::Headers[
						"content-type" => "text/html",
						"content-encoding" => "br"  # Server chose brotli
					], 
					["<compressed brotli content>"]  # This would be actual brotli data
				]
			}
			
			# Proxy middleware that only knows about gzip
			proxy_middleware = Protocol::HTTP::AcceptEncoding.new(upstream_delegate)
			
			# Client request that accepts both gzip and brotli
			request = Protocol::HTTP::Request["GET", "/some/resource"]
			response = proxy_middleware.call(request)
			
			# BUG: The content-encoding header should be preserved
			# so the client knows the content is still brotli-encoded
			expect(response.headers).to have_keys("content-encoding")
			expect(response.headers["content-encoding"]).to be == ["br"]
			
			# The body should remain untouched since proxy can't decode brotli
			expect(response.body).not.to be_a(Protocol::HTTP::Body::Inflate)
			expect(response.read).to be == "<compressed brotli content>"
		end
	end
	
	with "empty or identity encodings" do
		it "handles identity encoding correctly" do
			identity_delegate = ->(request) {
				Protocol::HTTP::Response[200, 
					Protocol::HTTP::Headers[
						"content-type" => "text/plain",
						"content-encoding" => "identity"
					], 
					["Hello World!"]
				]
			}
			
			identity_middleware = Protocol::HTTP::AcceptEncoding.new(identity_delegate)
			request = Protocol::HTTP::Request["GET", "/"]
			response = identity_middleware.call(request)
			
			# Identity encoding means no encoding, so header should be removed
			expect(response.headers).not.to have_keys("content-encoding")
			expect(response.body).not.to be_a(Protocol::HTTP::Body::Inflate)
		end
	end
end
