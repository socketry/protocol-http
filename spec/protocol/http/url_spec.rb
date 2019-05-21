# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'protocol/http/url'

RSpec.shared_examples_for "valid parameters" do |parameters, query_string = nil|
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

RSpec.describe Protocol::HTTP::URL do
	it_behaves_like "valid parameters", {'foo' => 'bar'}, "foo=bar"
	it_behaves_like "valid parameters", {'foo' => ["1", "2", "3"]}, "foo[]=1&foo[]=2&foo[]=3"
	
	it_behaves_like "valid parameters", {'foo' => {'bar' => 'baz'}}, "foo[bar]=baz"
	it_behaves_like "valid parameters", {'foo' => [{'bar' => 'baz'}]}, "foo[][bar]=baz"
	
	it_behaves_like "valid parameters", {'foo' => [{'bar' => 'baz'}, {'bar' => 'bob'}]}
	
	let(:encoded) {Protocol::HTTP::URL.encode(parameters)}
	
	context "basic parameters" do
		let(:parameters) {{x: "10", y: "20"}}
		let(:decoded) {Protocol::HTTP::URL.decode(encoded, symbolize_keys: true)}
		
		it "can symbolize keys" do
			expect(decoded).to be == parameters
		end
	end
	
	context "nested parameters" do
		let(:parameters) {{things: [{x: "10"}, {x: "20"}]}}
		let(:decoded) {Protocol::HTTP::URL.decode(encoded, symbolize_keys: true)}
		
		it "can symbolize keys" do
			expect(decoded).to be == parameters
		end
	end
	
	describe '.decode' do
		it "fails on deeply nested parameters" do
			expect do
				Protocol::HTTP::URL.decode("a[b][c][d][e][f][g][h][i]=10")
			end.to raise_error(/Key length exceeded/)
		end
	end
end
