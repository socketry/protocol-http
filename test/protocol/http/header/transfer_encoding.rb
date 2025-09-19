# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/http/header/transfer_encoding"

describe Protocol::HTTP::Header::TransferEncoding do
	let(:header) {subject.new(description)}
	
	with "chunked" do
		it "detects chunked encoding" do
			expect(header).to be(:chunked?)
		end
	end
	
	with "gzip" do
		it "detects gzip encoding" do
			expect(header).to be(:gzip?)
		end
	end
	
	with "deflate" do
		it "detects deflate encoding" do
			expect(header).to be(:deflate?)
		end
	end
	
	with "compress" do
		it "detects compress encoding" do
			expect(header).to be(:compress?)
		end
	end
	
	with "identity" do
		it "detects identity encoding" do
			expect(header).to be(:identity?)
		end
	end
	
	with "gzip, chunked" do
		it "handles multiple encodings" do
			expect(header.length).to be == 2
			expect(header).to be(:include?, "gzip")
			expect(header).to be(:include?, "chunked")
			expect(header).to be(:gzip?)
			expect(header).to be(:chunked?)
		end
	end
	
	with "empty header value" do
		let(:header) {subject.new}
		
		it "handles empty transfer encoding" do
			expect(header).to be(:empty?)
			expect(header).not.to be(:chunked?)
		end
	end
	
	with "#<<" do
		let(:header) {subject.new}
		
		it "can add encodings" do
			header << "gzip"
			expect(header).to be(:gzip?)
			
			header << "chunked"
			expect(header).to be(:chunked?)
		end
	end
	
	with ".trailer?" do
		it "should be forbidden in trailers" do
			expect(subject).not.to be(:trailer?)
		end
	end
end
