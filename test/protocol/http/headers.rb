# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.

require "protocol/http/headers"
require "protocol/http/cookie"

describe Protocol::HTTP::Headers do
	let(:fields) do
		[
			["Content-Type", "text/html"],
			["connection", "Keep-Alive"],
			["Set-Cookie", "hello=world"],
			["Accept", "*/*"],
			["set-cookie", "foo=bar"],
		].freeze
	end
	
	let(:headers) {subject[fields]}
	
	with ".new" do
		it "can construct headers with trailers" do
			headers = subject.new(fields, 4)
			expect(headers).to be(:trailer?)
			expect(headers.trailer.to_a).to be == [
				["set-cookie", "foo=bar"],
			]
		end
	end
	
	with ".[]" do
		it "can be constructed from frozen array" do
			self.fields.freeze
			
			expect(headers.fields).not.to be(:frozen?)
		end
	end
	
	with "#keys" do
		it "should return keys" do
			expect(headers.keys).to be == ["content-type", "connection", "set-cookie", "accept"]
		end
	end
	
	with "#trailer?" do
		it "should not be a trailer" do
			expect(headers).not.to be(:trailer?)
			expect(headers.tail).to be_nil
		end
	end
	
	with "#merge" do
		it "should merge headers" do
			other = subject[[
				# This will be appended:
				["Set-Cookie", "goodbye=world"],
			]]
			
			merged = headers.merge(other)
			
			expect(merged.to_h).to be == {
				"content-type" => "text/html",
				"set-cookie" => ["hello=world", "foo=bar", "goodbye=world"],
				"accept" => ["*/*"],
				"connection" => ["keep-alive"]
			}
		end
		
		it "can't merge singleton headers" do
			other = subject[[
				["content-type", "text/plain"],
			]]
			
			# This doesn't fail as we haven't built an internal index yet:
			merged = headers.merge(other)
			
			expect do
				# Once we build the index, it will fail:
				merged.to_h
			end.to raise_exception(Protocol::HTTP::DuplicateHeaderError)
		end
	end
	
	with "#extract" do
		it "can extract named fields" do
			# Force the headers to be indexed:
			headers.to_h
			
			expect(headers.extract(["content-type", "set-cookie"])).to be == [
				["Content-Type", "text/html"],
				["Set-Cookie", "hello=world"],
				["set-cookie", "foo=bar"],
			]
		end
	end
	
	with "#clear" do
		it "should clear headers" do
			headers.clear
			
			expect(headers.fields).to be(:empty?)
		end
	end
	
	with "#freeze" do
		it "can't modify frozen headers" do
			headers.freeze
			
			expect(headers.fields).to be == fields
			expect(headers.fields).to be(:frozen?)
			expect(headers.to_h).to be(:frozen?)
		end
		
		it "returns duplicated headers if they are frozen" do
			headers.freeze
			
			expect(subject[headers]).not.to be(:frozen?)
		end
	end
	
	with "#dup" do
		it "should not modify source object" do
			headers = self.headers.dup
			
			headers["field"] = "value"
			
			expect(self.headers).not.to be(:include?, "field")
		end
	end
	
	with "#empty?" do
		it "shouldn't be empty" do
			expect(headers).not.to be(:empty?)
		end
	end
	
	with "#include?" do
		it "should include? named fields" do
			expect(headers).to be(:include?, "set-cookie")
		end
	end
	
	with "#key?" do
		it "should key? named fields" do
			expect(headers).to be(:key?, "set-cookie")
		end
	end
	
	with "#fields" do
		it "should add fields in order" do
			expect(headers.fields).to be == fields
		end
		
		it "can enumerate fields" do
			headers.fields.each_with_index do |field, index|
				expect(field).to be == fields[index]
			end
		end
	end
	
	with "#to_a" do
		it "should return the fields array" do
			expect(headers.to_a).to be == fields
		end
		
		it "should return the same object as fields" do
			expect(headers.to_a).to be_equal(headers.fields)
		end
		
		it "should return an array" do
			expect(headers.to_a).to be_a(Array)
		end
	end
	
	with "#to_h" do
		it "should generate array values for duplicate keys" do
			expect(headers.to_h["set-cookie"]).to be == ["hello=world", "foo=bar"]
		end
	end
	
	with "#inspect" do
		it "should generate a string representation" do
			expect(headers.inspect).to be == "#<Protocol::HTTP::Headers #{fields.inspect}>"
		end
	end
	
	with "#[]" do
		it "can lookup fields" do
			expect(headers["content-type"]).to be == "text/html"
		end
	end
	
	with "#[]=" do
		it "can add field with a String value" do
			headers["Content-Length"] = "1"
			
			expect(headers.fields.last).to be == ["content-length", "1"]
			expect(headers["content-length"]).to be == "1"
		end
		
		it "can add field with an Integer value" do
			headers["Content-Length"] = 1
			
			expect(headers.fields.last).to be == ["content-length", "1"]
			expect(headers["content-length"]).to be == "1"
		end
		
		it "can add field with an Array value" do
			headers["accept-encoding"] = ["gzip", "deflate"]
			expect(headers["accept-encoding"]).to be(:include?, "gzip")
			expect(headers["accept-encoding"]).to be(:include?, "deflate")
		end
		
		it "can add field with indexed hash" do
			expect(headers.to_h).not.to be(:empty?)
			
			headers["Content-Length"] = "1"
			expect(headers["content-length"]).to be == "1"
		end
	end
	
	with "#add" do
		it "can add field" do
			headers.add("Content-Length", 1)
			
			expect(headers.fields.last).to be == ["Content-Length", "1"]
			expect(headers["content-length"]).to be == "1"
		end
	end
	
	with "#set" do
		it "can replace an existing field" do
			headers.add("accept-encoding", "gzip,deflate")
			
			headers.set("accept-encoding", "gzip")
			
			expect(headers["accept-encoding"]).to be == ["gzip"]
		end
	end
	
	with "#extract" do
		it "can extract key's that don't exist" do
			expect(headers.extract("foo")).to be(:empty?)
		end
		
		it "can extract single key" do
			expect(headers.extract("content-type")).to be == [["Content-Type", "text/html"]]
		end
	end
	
	with "#==" do
		it "can compare with array" do
			expect(headers).to be == fields
		end
		
		it "can compare with itself" do
			expect(headers).to be == headers
		end
		
		it "can compare with hash" do
			expect(headers).not.to be == {}
		end
	end
	
	with "#delete" do
		it "can delete case insensitive fields" do
			expect(headers.delete("content-type")).to be == "text/html"
			
			expect(headers.fields).to be == fields[1..-1]
		end
		
		it "can delete non-existant fields" do
			expect(headers.delete("transfer-encoding")).to be_nil
		end
	end
	
	with "#merge" do
		it "can merge content-length" do
			headers.merge!("content-length" => 2)
			
			expect(headers["content-length"]).to be == "2"
		end
	end
	
	with "#trailer!" do
		it "can add trailer" do
			headers.add("trailer", "etag")
			count = headers.fields.size
			
			trailer = headers.trailer!
			expect(headers.tail).to be == count
			
			headers.add("etag", "abcd")
			
			expect(trailer.to_a).to be == [["etag", "abcd"]]
		end
		
		it "can add trailer without explicit header" do
			trailer = headers.trailer!
			
			headers.add("etag", "abcd")
			
			expect(trailer.to_a).to be == [["etag", "abcd"]]
		end
		
		with "forbidden trailers" do
			let(:headers) {subject.new}
			
			forbidden_trailers = %w[
				accept
				accept-charset
				accept-encoding
				accept-language
				
				authorization
				proxy-authorization
				www-authenticate
				proxy-authenticate
				
				connection
				content-length
				transfer-encoding
				te
				upgrade
				trailer
				
				host
				expect
				range
				
				content-type
				content-encoding
				content-range
				
				cookie
				set-cookie
			]
			
			forbidden_trailers.each do |key|
				with "forbidden trailer #{key.inspect}", unique: key do
					it "can't add a #{key.inspect} header in the trailer" do
						trailer = headers.trailer!
						expect do
							headers.add(key, "example", trailer: true)
						end.to raise_exception(Protocol::HTTP::InvalidTrailerError)
					end
					
					it "can't add a #{key.inspect} header with trailer: true" do
						expect do
							headers.add(key, "example", trailer: true)
						end.to raise_exception(Protocol::HTTP::InvalidTrailerError)
					end
				end
			end
		end
		
		with "unknown trailers", unique: "unknown" do
			let(:headers) {subject.new}
			
			unknown_trailers = %w[
				x-foo-bar
				grpc-status
				grpc-message
				x-custom-header
			]
			
			unknown_trailers.each do |key|
				with "unknown trailer #{key.inspect}", unique: key do
					it "can add unknown header #{key.inspect} as trailer" do
						headers.add(key, "example", trailer: true)
						expect(headers).to be(:include?, key)
					end
				end
			end
		end
		
		with "permitted trailers" do
			let(:headers) {subject.new}
			
			permitted_trailers = [
				"date",
				"digest",
				"etag",
				"server-timing",
			]
			
			permitted_trailers.each do |key|
				with "permitted trailer #{key.inspect}", unique: key do
					it "can add a #{key.inspect} header in the trailer" do
						trailer = headers.trailer!
						headers.add(key, "example")
						expect(headers).to be(:include?, key)
					end
					
					it "can add a #{key.inspect} header with trailer: true" do
						headers.add(key, "example", trailer: true)
						expect(headers).to be(:include?, key)
					end
				end
			end
		end
	end
	
	with "#header" do
		it "can enumerate all headers when there are no trailers" do
			result = headers.header.to_a
			
			expect(result).to be == fields
		end
		
		it "enumerates headers but not trailers" do
			headers.trailer!
			headers.add("etag", "abcd")
			headers.add("digest", "sha-256=xyz")
			
			header = headers.header.to_a
			
			# Should only include the original 5 fields, not the 2 trailers
			expect(header.size).to be == 5
			expect(header).to be == fields
		end
		
		it "returns an enumerator when no block is given" do
			enumerator = headers.header
			
			expect(enumerator).to be_a(Enumerator)
			expect(enumerator.to_a).to be == fields
		end
		
		it "returns an enumerator that excludes trailers" do
			headers.trailer!
			headers.add("etag", "abcd")
			
			enumerator = headers.header
			
			expect(enumerator).to be_a(Enumerator)
			expect(enumerator.to_a.size).to be == 5
			expect(enumerator.to_a).to be == [
				["Content-Type", "text/html"],
				["connection", "Keep-Alive"],
				["Set-Cookie", "hello=world"],
				["Accept", "*/*"],
				["set-cookie", "foo=bar"]
			]
		end
	end
	
	with "#trailer" do
		it "can enumerate trailer" do
			headers.add("trailer", "etag")
			headers.trailer!
			headers.add("etag", "abcd")
			
			expect(headers.trailer.to_a).to be == [["etag", "abcd"]]
		end
	end
	
	with "#add with trailer: keyword" do
		let(:headers) {subject.new}
		
		it "allows adding regular headers without trailer: true" do
			headers.add("content-type", "text/plain")
			expect(headers["content-type"]).to be == "text/plain"
		end
		
		it "validates trailers immediately when trailer: true" do
			expect do
				headers.add("content-type", "text/plain", trailer: true)
			end.to raise_exception(Protocol::HTTP::InvalidTrailerError)
		end
		
		it "allows permitted trailers with trailer: true" do
			headers.add("etag", "abcd", trailer: true)
			expect(headers["etag"]).to be == "abcd"
		end
		
		it "validates trailers without calling trailer! first" do
			# This should fail immediately, without needing trailer! to be called
			expect do
				headers.add("authorization", "Bearer token", trailer: true)
			end.to raise_exception(Protocol::HTTP::InvalidTrailerError)
		end
		
		it "validates trailers even when headers are not indexed" do
			# Add without triggering indexing
			expect do
				headers.add("host", "example.com", trailer: true)
			end.to raise_exception(Protocol::HTTP::InvalidTrailerError)
			
			# Ensure we haven't triggered indexing yet
			expect(headers.instance_variable_get(:@indexed)).to be_nil
		end
	end
	
	with "custom policy" do
		let(:headers) {subject.new}
		
		# Create a custom header class that allows trailers
		let(:grpc_status_class) do
			Class.new(String) do
				def self.parse(value)
					new(value)
				end
				
				def self.trailer?
					true
				end
			end
		end
		
		it "can set custom policy to allow additional trailer headers" do
			# Create custom policy that allows grpc-status as trailer
			custom_policy = Protocol::HTTP::Headers::POLICY.dup
			custom_policy["grpc-status"] = grpc_status_class
			
			# Set the custom policy
			headers.policy = custom_policy
			
			# Enable trailers
			headers.trailer!
			
			# Add grpc-status header (should be allowed with custom policy)
			headers.add("grpc-status", "0")
			
			# Verify it appears in trailers
			expect(headers).to be(:include?, "grpc-status")
			
			trailer_headers = {}
			headers.trailer do |key, value|
				trailer_headers[key] = value
			end
			
			expect(trailer_headers["grpc-status"]).to be == "0"
		end
		
		it "policy= clears indexed cache" do
			# Add some headers first
			headers.add("content-type", "text/html")
			
			# Force indexing
			hash1 = headers.to_h
			expect(hash1).to be(:include?, "content-type")
			
			# Change policy
			new_policy = {}
			headers.policy = new_policy
			
			# Add another header
			headers.add("x-custom", "value")
			
			# Verify cache was cleared and rebuilt
			hash2 = headers.to_h
			expect(hash2).to be(:include?, "content-type")
			expect(hash2).to be(:include?, "x-custom")
		end
		
		it "can read policy attribute" do
			original_policy = headers.policy
			expect(original_policy).to be == Protocol::HTTP::Headers::POLICY
			
			# Set new policy
			custom_policy = {"custom" => String}
			headers.policy = custom_policy
			
			# Verify policy was changed
			expect(headers.policy).to be == custom_policy
			expect(headers.policy).not.to be == original_policy
		end
	end
	
	with "#flatten!" do
		it "can flatten trailer" do
			headers.add("trailer", "etag")
			trailer = headers.trailer!
			headers.add("etag", "abcd")
			
			headers.flatten!
			
			expect(headers).not.to have_keys("trailer")
			expect(headers).to have_keys("etag")
		end
	end
	
	with "#flatten" do
		it "can flatten trailer" do
			headers.add("trailer", "etag")
			trailer = headers.trailer!
			headers.add("etag", "abcd")
			
			copy = headers.flatten
			
			expect(headers).to have_keys("trailer")
			expect(headers).to have_keys("etag")
			
			expect(copy).not.to have_keys("trailer")
			expect(copy).to have_keys("etag")
		end
	end
	
	with "set-cookie" do
		it "can extract parsed cookies" do
			expect(headers["set-cookie"]).to be_a(Protocol::HTTP::Header::Cookie)
		end
	end
	
	with "connection" do
		it "can extract connection options" do
			expect(headers["connection"]).to be_a(Protocol::HTTP::Header::Connection)
		end
		
		it "should normalize to lower case" do
			expect(headers["connection"]).to be == ["keep-alive"]
		end
	end
end

describe Protocol::HTTP::Headers::Merged do
	let(:merged) do
		Protocol::HTTP::Headers::Merged.new(
			Protocol::HTTP::Headers["content-type" => "text/html"],
			Protocol::HTTP::Headers["content-encoding" => "gzip"]
		)
	end
	
	with "#flatten" do
		let(:flattened) {merged.flatten}
		
		it "can combine all headers" do
			expect(flattened).to be_a Protocol::HTTP::Headers
			expect(flattened.fields).to be == [
				["content-type", "text/html"],
				["content-encoding", "gzip"]
			]
		end
	end
	
	with "#clear" do
		it "can clear all headers" do
			merged.clear
			
			expect(merged.flatten).to be(:empty?)
		end
	end
	
	with "#each" do
		it "can iterate over all headers" do
			expect(merged.each.to_a).to be == [
				["content-type", "text/html"],
				["content-encoding", "gzip"]
			]
		end
	end
	
	with "non-normalized case" do
		let(:merged) do
			Protocol::HTTP::Headers::Merged.new(
				Protocol::HTTP::Headers["Content-Type" => "text/html"],
				Protocol::HTTP::Headers["Content-Encoding" => "gzip"]
			)
		end
		
		it "can normalize case" do
			expect(merged.each.to_a).to be == [
				["content-type", "text/html"],
				["content-encoding", "gzip"]
			]
		end
	end
end
