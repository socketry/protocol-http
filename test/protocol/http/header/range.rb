# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/header/range"

describe Protocol::HTTP::Header::Range do
	it "classifies parse errors as bad requests" do
		expect(subject::ParseError.new).to be_a(Protocol::HTTP::BadRequest)
	end
	
	with ".parse" do
		it "parses byte ranges" do
			header = subject.parse("bytes=0-4, 10-, -5")
			
			expect(header.unit).to be == "bytes"
			expect(header.ranges).to be == [
				subject::ByteRange.new(0, 4),
				subject::ByteRange.new(10, nil),
				subject::ByteRange.new(nil, 5),
			]
			expect(header.to_s).to be == "bytes=0-4,10-,-5"
		end
		
		it "normalizes the unit" do
			header = subject.parse("BYTES=0-4")
			
			expect(header.unit).to be == "bytes"
		end
		
		it "preserves extension ranges" do
			header = subject.parse("example=alpha, beta")
			
			expect(header.unit).to be == "example"
			expect(header.ranges).to be == ["alpha", "beta"]
		end
		
		it "rejects malformed headers" do
			[
				"bytes",
				"bytes=",
				"bytes=0-1,",
				"bytes=-",
				"bytes=4-1",
				"bytes=one-two",
				"example=alpha beta",
			].each do |value|
				expect{subject.parse(value)}.to raise_exception(subject::ParseError)
			end
		end
	end
	
	with "#resolve" do
		it "resolves bounded byte ranges" do
			header = subject.parse("bytes=1-4")
			
			expect(header.resolve(12)).to be == [1..4]
		end
		
		it "resolves open-ended byte ranges" do
			header = subject.parse("bytes=8-")
			
			expect(header.resolve(12)).to be == [8..11]
		end
		
		it "resolves suffix byte ranges" do
			header = subject.parse("bytes=-5")
			
			expect(header.resolve(12)).to be == [7..11]
		end
		
		it "clamps byte ranges to the representation size" do
			header = subject.parse("bytes=1-999,-999")
			
			expect(header.resolve(12)).to be == [1..11, 0..11]
		end
		
		it "omits unsatisfiable byte ranges" do
			header = subject.parse("bytes=999-1000,-0")
			
			expect(header.resolve(12)).to be == []
		end
		
		it "does not resolve extension ranges as byte ranges" do
			header = subject.parse("example=alpha")
			
			expect{header.resolve(12)}.to raise_exception(ArgumentError)
		end
		
		it "rejects a negative representation size" do
			header = subject.parse("bytes=0-1")
			
			expect{header.resolve(-1)}.to raise_exception(ArgumentError)
		end
	end
	
	with "#<<" do
		it "combines ranges with the same unit" do
			header = subject.parse("bytes=0-1")
			header << "bytes=4-5"
			
			expect(header.resolve(10)).to be == [0..1, 4..5]
		end
		
		it "rejects ranges with a different unit" do
			header = subject.parse("bytes=0-1")
			
			expect{header << "example=alpha"}.to raise_exception(subject::ParseError)
		end
	end
	
	with ".trailer?" do
		it "is not allowed in trailers" do
			expect(subject).not.to be(:trailer?)
		end
	end
end
