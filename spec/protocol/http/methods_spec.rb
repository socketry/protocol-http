# frozen_string_literal: true

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

require 'protocol/http/methods'

RSpec.describe Protocol::HTTP::Methods do
	it "defines several methods" do
		expect(described_class.constants).to_not be_empty
	end
	
	shared_examples_for Protocol::HTTP::Methods do |name|
		it "defines #{name} method" do
			expect(described_class.constants).to include(name.to_sym)
		end
		
		it "has correct value" do
			expect(described_class.const_get(name)).to be == name.to_s
		end
		
		it "is a valid method" do
			expect(described_class).to be_valid(name)
		end
	end
	
	it_behaves_like Protocol::HTTP::Methods, "GET"
	it_behaves_like Protocol::HTTP::Methods, "POST"
	it_behaves_like Protocol::HTTP::Methods, "PUT"
	it_behaves_like Protocol::HTTP::Methods, "PATCH"
	it_behaves_like Protocol::HTTP::Methods, "DELETE"
	it_behaves_like Protocol::HTTP::Methods, "HEAD"
	it_behaves_like Protocol::HTTP::Methods, "OPTIONS"
	it_behaves_like Protocol::HTTP::Methods, "LINK"
	it_behaves_like Protocol::HTTP::Methods, "UNLINK"
	it_behaves_like Protocol::HTTP::Methods, "TRACE"
	it_behaves_like Protocol::HTTP::Methods, "CONNECT"
	
	it "defines exactly 11 methods" do
		expect(described_class.constants.length).to be == 11
	end
	
	describe '.valid?' do
		subject {described_class}
		
		describe "FOOBAR" do
			it {is_expected.to_not be_valid(description)}
		end
		
		describe "GETEMALL" do
			it {is_expected.to_not be_valid(description)}
		end
		
		describe "Accept:" do
			it {is_expected.to_not be_valid(description)}
		end
	end
end
