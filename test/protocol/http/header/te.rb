# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/http/header/te"

describe Protocol::HTTP::Header::TE do
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
	
	with "trailers" do
		it "detects trailers acceptance" do
			expect(header).to be(:trailers?)
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
	
	with "gzip;q=0.8, chunked;q=1.0" do
		it "parses quality factors" do
			codings = header.transfer_codings
			expect(codings.length).to be == 2
			expect(codings[0].name).to be == "gzip"
			expect(codings[0].quality_factor).to be == 0.8
			expect(codings[1].name).to be == "chunked"
			expect(codings[1].quality_factor).to be == 1.0
		end
		
		it "contains expected encodings" do
			expect(header).to be(:gzip?)
			expect(header).to be(:chunked?)
		end
	end
	
	with "gzip;q=0.5, deflate;q=0.8" do
		it "handles multiple quality factors" do
			codings = header.transfer_codings.sort
			expect(codings[0].name).to be == "deflate"  # higher quality first
			expect(codings[1].name).to be == "gzip"
		end
	end
	
	with "" do
		let(:header) {subject.new}
		
		it "handles empty TE header" do
			expect(header).to be(:empty?)
			expect(header).not.to be(:chunked?)
		end
	end
	
	with "#<<" do
		let(:header) {subject.new}
		
		it "can add encodings" do
			header << "gzip"
			expect(header).to be(:gzip?)
			
			header << "chunked;q=0.9"
			expect(header).to be(:chunked?)
		end
	end
	
	with "error handling" do
		it "raises ParseError for invalid transfer coding" do
			header = subject.new("invalid@encoding")
			expect do
				header.transfer_codings
			end.to raise_exception(Protocol::HTTP::Header::TE::ParseError)
		end
	end
	
	with "TransferCoding struct" do
		it "handles quality factor conversion" do
			coding = Protocol::HTTP::Header::TE::TransferCoding.new("gzip", "0.8")
			expect(coding.quality_factor).to be == 0.8
		end
		
		it "defaults quality factor to 1.0" do
			coding = Protocol::HTTP::Header::TE::TransferCoding.new("gzip", nil)
			expect(coding.quality_factor).to be == 1.0
		end
		
		it "serializes with quality factor" do
			coding = Protocol::HTTP::Header::TE::TransferCoding.new("gzip", "0.8")
			expect(coding.to_s).to be == "gzip;q=0.8"
		end
		
		it "serializes without quality factor when 1.0" do
			coding = Protocol::HTTP::Header::TE::TransferCoding.new("gzip", nil)
			expect(coding.to_s).to be == "gzip"
		end
		
		it "compares by quality factor" do
			high = Protocol::HTTP::Header::TE::TransferCoding.new("gzip", "0.9")
			low = Protocol::HTTP::Header::TE::TransferCoding.new("deflate", "0.5")
			expect(high <=> low).to be == -1  # high quality first
		end
	end
	
	with ".trailer?" do
		it "should be forbidden in trailers" do
			expect(subject).not.to be(:trailer?)
		end
	end
end