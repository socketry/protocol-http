# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.

require "protocol/http/headers"
require "protocol/http/cookie"

describe Protocol::HTTP::Headers do
	let(:fields) do
		[
			["Content-Type", "text/html"],
			["Set-Cookie", "hello=world"],
			["Accept", "*/*"],
			["set-cookie", "foo=bar"],
			["connection", "Keep-Alive"]
		]
	end
	
	let(:headers) {subject[fields]}
	
	with ".[]" do
		it "can be constructed from frozen array" do
			self.fields.freeze
			
			expect(headers.fields).not.to be(:frozen?)
		end
	end
	
	with "#keys" do
		it "should return keys" do
			expect(headers.keys).to be == ["content-type", "set-cookie", "accept", "connection"]
		end
	end
	
	with "#trailer?" do
		it "should not be a trailer" do
			expect(headers).not.to be(:trailer?)
		end
	end
	
	with "#merge" do
		it "should merge headers" do
			other = subject[[
				# This will replace the original one:
				["Content-Type", "text/plain"],
				
				# This will be appended:
				["Set-Cookie", "goodbye=world"],
			]]
			
			merged = headers.merge(other)
			
			expect(merged.to_h).to be == {
				"content-type" => "text/plain",
				"set-cookie" => ["hello=world", "foo=bar", "goodbye=world"],
				"accept" => ["*/*"],
				"connection" => ["keep-alive"]
			}
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
			headers.each.with_index do |field, index|
				expect(field).to be == fields[index]
			end
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
		it "can add field" do
			headers["Content-Length"] = 1
			
			expect(headers.fields.last).to be == ["Content-Length", 1]
			expect(headers["content-length"]).to be == 1
		end
		
		it "can add field with indexed hash" do
			expect(headers.to_h).not.to be(:empty?)
			
			headers["Content-Length"] = 1
			expect(headers["content-length"]).to be == 1
		end
	end
	
	with "#add" do
		it "can add field" do
			headers.add("Content-Length", 1)
			
			expect(headers.fields.last).to be == ["Content-Length", 1]
			expect(headers["content-length"]).to be == 1
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
			
			expect(headers["content-length"]).to be == 2
		end
	end
	
	with "#trailer!" do
		it "can add trailer" do
			headers.add("trailer", "etag")
			
			trailer = headers.trailer!
			
			headers.add("etag", "abcd")
			
			expect(trailer.to_h).to be == {"etag" => "abcd"}
		end
		
		it "can add trailer without explicit header" do
			trailer = headers.trailer!
			
			headers.add("etag", "abcd")
			
			expect(trailer.to_h).to be == {"etag" => "abcd"}
		end
	end
	
	with "#trailer" do
		it "can enumerate trailer" do
			headers.add("trailer", "etag")
			headers.trailer!
			headers.add("etag", "abcd")
			
			expect(headers.trailer.to_h).to be == {"etag" => "abcd"}
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
			Protocol::HTTP::Headers.new("content-type" => "text/html"),
			Protocol::HTTP::Headers.new("content-encoding" => "gzip")
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
				Protocol::HTTP::Headers.new("Content-Type" => "text/html"),
				Protocol::HTTP::Headers.new("Content-Encoding" => "gzip")
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
