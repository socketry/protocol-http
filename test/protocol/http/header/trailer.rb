# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/http/header/trailer"

describe Protocol::HTTP::Header::Trailer do
	let(:header) {subject.new(description)}
	
	with "etag" do
		it "contains etag header" do
			expect(header).to be(:include?, "etag")
		end
		
		it "has one header" do
			expect(header.length).to be == 1
		end
	end
	
	with "etag, content-md5" do
		it "contains multiple headers" do
			expect(header).to be(:include?, "etag")
			expect(header).to be(:include?, "content-md5")
		end
		
		it "has correct count" do
			expect(header.length).to be == 2
		end
	end
	
	with "etag, content-md5, expires" do
		it "handles three headers" do
			expect(header).to be(:include?, "etag")
			expect(header).to be(:include?, "content-md5")
			expect(header).to be(:include?, "expires")
		end
		
		it "serializes correctly" do
			expect(header.to_s).to be == "etag,content-md5,expires"
		end
	end
	
	with "etag , content-md5 , expires" do
		it "strips whitespace" do
			expect(header.length).to be == 3
			expect(header).to be(:include?, "etag")
			expect(header).to be(:include?, "content-md5")
		end
	end
	
	with "empty header value" do
		let(:header) {subject.new}
		
		it "handles empty trailer" do
			expect(header).to be(:empty?)
			expect(header.to_s).to be == ""
		end
	end
	
	with "#<<" do
		let(:header) {subject.new("etag")}
		
		it "can add headers" do
			header << "content-md5, expires"
			expect(header.length).to be == 3
			expect(header).to be(:include?, "expires")
		end
	end
	
	with ".trailer?" do
		it "should be forbidden in trailers" do
			expect(subject).not.to be(:trailer?)
		end
	end
end
