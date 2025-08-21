# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2022, by Herrick Fang.

require "protocol/http/url"

ValidParameters = Sus::Shared("valid parameters") do |parameters, query_string = nil|
	let(:encoded) {Protocol::HTTP::URL.encode(parameters)}
	
	if query_string
		it "can encode #{parameters.inspect}" do
			expect(encoded).to be == query_string
		end
	end
	
	let(:decoded) {Protocol::HTTP::URL.decode(encoded)}
	
	it "can round-trip #{parameters.inspect}" do
		expect(decoded).to be == parameters
	end
end

describe Protocol::HTTP::URL do
	it_behaves_like ValidParameters, {"foo" => "bar"}, "foo=bar"
	it_behaves_like ValidParameters, {"foo" => ["1", "2", "3"]}, "foo[]=1&foo[]=2&foo[]=3"
	
	it_behaves_like ValidParameters, {"foo" => {"bar" => "baz"}}, "foo[bar]=baz"
	it_behaves_like ValidParameters, {"foo" => [{"bar" => "baz"}]}, "foo[][bar]=baz"
	
	it_behaves_like ValidParameters, {"foo" => [{"bar" => "baz"}, {"bar" => "bob"}]}
	
	RoundTrippedParameters = Sus::Shared("round-tripped parameters") do
		let(:encoded) {Protocol::HTTP::URL.encode(parameters)}
		let(:decoded) {Protocol::HTTP::URL.decode(encoded, symbolize_keys: true)}
		
		it "can round-trip parameters" do
			expect(decoded).to be == parameters
		end
	end
	
	with "basic parameters" do
		let(:parameters) {{x: "10", y: "20"}}
		
		it_behaves_like RoundTrippedParameters
	end
	
	with "nested parameters" do
		let(:parameters) {{things: [{x: "10"}, {x: "20"}]}}
		
		it_behaves_like RoundTrippedParameters
	end
	
	with "nil values" do
		let(:parameters) {{x: nil}}
		
		it_behaves_like RoundTrippedParameters
	end
	
	with "nil values in arrays" do
		let(:parameters) {{x: ["1", nil, "2"]}}
		
		it_behaves_like RoundTrippedParameters
	end
	
	with ".decode" do
		it "fails on deeply nested parameters" do
			expect do
				Protocol::HTTP::URL.decode("a[b][c][d][e][f][g][h][i]=10")
			end.to raise_exception(ArgumentError, message: be =~ /Key length exceeded/)
		end
		
		it "fails with missing key" do
			expect do
				Protocol::HTTP::URL.decode("=foo")
			end.to raise_exception(ArgumentError, message: be =~ /Invalid key/)
		end
		
		it "fails with empty pairs" do
			expect(Protocol::HTTP::URL.decode("a=1&&b=2")).to be == {"a" => "1", "b" => "2"}
			expect(Protocol::HTTP::URL.decode("a&&b")).to be == {"a" => nil, "b" => nil}
		end
	end
	
	with ".unescape" do
		it "succeds with hex characters" do
			expect(Protocol::HTTP::URL.unescape("%3A")).to be == ":"
		end
	end
end
