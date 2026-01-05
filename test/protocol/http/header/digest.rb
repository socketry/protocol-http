# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025-2026, by Samuel Williams.

require "protocol/http/header/digest"
require "sus"

describe Protocol::HTTP::Header::Digest do
	let(:header) {subject.parse(description)}
	
	with "empty header" do
		let(:header) {subject.new}
		
		it "should be empty" do
			expect(header.to_s).to be == ""
		end
		
		it "should be an array" do
			expect(header).to be_a(Array)
		end
		
		it "should return empty entries" do
			expect(header.entries).to be == []
		end
	end
	
	with "sha-256=X48E9qOokqqrvdts8nOJRJN3OWDUoyWxBf7kbu9DBPE=" do
		it "can parse a single entry" do
			entries = header.entries
			expect(entries.size).to be == 1
			expect(entries.first.algorithm).to be == "sha-256"
			expect(entries.first.value).to be == "X48E9qOokqqrvdts8nOJRJN3OWDUoyWxBf7kbu9DBPE="
		end
	end
	
	with "sha-256=X48E9qOokqqrvdts8nOJRJN3OWDUoyWxBf7kbu9DBPE=, md5=9bb58f26192e4ba00f01e2e7b136bbd8" do
		it "can parse multiple entries" do
			entries = header.entries
			expect(entries.size).to be == 2
			expect(entries[0].algorithm).to be == "sha-256"
			expect(entries[1].algorithm).to be == "md5"
		end
	end
	
	with "SHA-256=abc123" do
		it "normalizes algorithm to lowercase" do
			entries = header.entries
			expect(entries.first.algorithm).to be == "sha-256"
		end
	end
	
	with "sha-256 = X48E9qOokqqrvdts8nOJRJN3OWDUoyWxBf7kbu9DBPE=" do
		it "handles whitespace around equals sign" do
			entries = header.entries
			expect(entries.first.algorithm).to be == "sha-256"
			expect(entries.first.value).to be == "X48E9qOokqqrvdts8nOJRJN3OWDUoyWxBf7kbu9DBPE="
		end
	end
	
	with "invalid-format-no-equals" do
		it "raises ParseError for invalid format" do
			expect do
				header.entries
			end.to raise_exception(Protocol::HTTP::Header::Digest::ParseError)
		end
	end
	
	with "#<<" do
		let(:header) {subject.new}
		
		it "can add entries from string" do
			header << "sha-256=abc123"
			header << "md5=def456"
			expect(header.size).to be == 2
			
			entries = header.entries
			expect(entries[0].algorithm).to be == "sha-256"
			expect(entries[1].algorithm).to be == "md5"
		end
		
		it "can add multiple entries at once" do
			header << "sha-256=abc123, md5=def456"
			expect(header.size).to be == 2
			
			entries = header.entries
			expect(entries[0].algorithm).to be == "sha-256"
			expect(entries[1].algorithm).to be == "md5"
		end
	end
	
	with "inherited Split behavior" do
		let(:header) {subject.new}
		
		it "behaves as an array" do
			header << "sha-256=abc123"
			expect(header.size).to be == 1
			expect(header.first).to be == "sha-256=abc123"
		end
		
		it "can be enumerated" do
			header << "sha-256=abc123, md5=def456"
			values = []
			header.each{|value| values << value}
			expect(values).to be == ["sha-256=abc123", "md5=def456"]
		end
		
		it "supports array methods" do
			header << "sha-256=abc123, md5=def456"
			expect(header.length).to be == 2
			expect(header.empty?).to be == false
		end
	end
	
	with "trailer support" do
		it "should be allowed as a trailer" do
			expect(subject.trailer?).to be == true
		end
	end
	
	with "algorithm edge cases" do
		it "handles hyphenated algorithms" do
			header = subject.parse("sha-256=abc123")
			entries = header.entries
			expect(entries.first.algorithm).to be == "sha-256"
		end
		
		it "handles numeric algorithms" do
			header = subject.parse("md5=def456")
			entries = header.entries
			expect(entries.first.algorithm).to be == "md5"
		end
	end
	
	with "value edge cases" do
		it "handles empty values" do
			header = subject.parse("sha-256=")
			entries = header.entries
			expect(entries.first.value).to be == ""
		end
		
		it "handles values with special characters" do
			header = subject.parse("sha-256=abc+def/123==")
			entries = header.entries
			expect(entries.first.value).to be == "abc+def/123=="
		end
	end
end

describe Protocol::HTTP::Header::Digest::Entry do
	it "can create entry directly" do
		entry = subject.new("sha-256", "abc123")
		expect(entry.algorithm).to be == "sha-256"
		expect(entry.value).to be == "abc123"
		expect(entry.to_s).to be == "sha-256=abc123"
	end
	
	it "normalizes algorithm to lowercase" do
		entry = subject.new("SHA-256", "abc123")
		expect(entry.algorithm).to be == "sha-256"
	end
	
	it "handles complex algorithm names" do
		entry = subject.new("sha-384", "complex-value")
		expect(entry.algorithm).to be == "sha-384"
		expect(entry.to_s).to be == "sha-384=complex-value"
	end
	
	it "handles base64 padding in values" do
		entry = subject.new("md5", "abc123==")
		expect(entry.value).to be == "abc123=="
	end
end
