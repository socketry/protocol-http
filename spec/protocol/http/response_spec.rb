# frozen_string_literal: true

# Copyright, 2020, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'protocol/http/request'

RSpec.describe Protocol::HTTP::Response do
	let(:headers) {Protocol::HTTP::Headers.new}
	let(:body) {nil}
	
	context "simple GET request" do
		subject {described_class.new("HTTP/1.0", 200, headers, body)}
		
		it {is_expected.to have_attributes(
			version: "HTTP/1.0",
			status: 200,
			headers: headers,
			body: body,
			protocol: nil
		)}
		
		it {is_expected.to_not be_hijack}
		it {is_expected.to_not be_continue}
		it {is_expected.to be_success}
		
		it {is_expected.to have_attributes(
			to_ary: [200, headers, body]
		)}
		
		it {is_expected.to have_attributes(
			to_s: "200 HTTP/1.0"
		)}
	end
end
