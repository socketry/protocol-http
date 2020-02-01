# frozen_string_literal: true

# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'protocol/http/headers'
require 'protocol/http/cookie'

RSpec.describe Protocol::HTTP::Header::Connection do
	context "connection: close" do
		subject {described_class.new("close")}
		
		it "should indiciate connection will be closed" do
			expect(subject).to be_close
		end
		
		it "should indiciate connection will not be keep-alive" do
			expect(subject).to_not be_keep_alive
		end
	end
	
	context "connection: keep-alive" do
		subject {described_class.new("keep-alive")}
		
		it "should indiciate connection will not be closed" do
			expect(subject).to_not be_close
		end
		
		it "should indiciate connection is not keep-alive" do
			expect(subject).to be_keep_alive
		end
	end
	
	context "connection: upgrade" do
		subject {described_class.new("upgrade")}
		
		it "should indiciate connection can be upgraded" do
			expect(subject).to be_upgrade
		end
	end
end
