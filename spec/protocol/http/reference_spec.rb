#!/usr/bin/env ruby

# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'protocol/http/reference'

RSpec.describe Protocol::HTTP::Reference do
	describe '#+' do
		let(:absolute) {described_class['/foo/bar']}
		let(:relative) {described_class['foo/bar']}
		let(:up) {described_class['../baz']}
		
		it 'can add a relative path' do
			expect(subject + relative).to be == absolute
		end
		
		it 'can add an absolute path' do
			expect(subject + absolute).to be == absolute
		end
		
		it 'can add an absolute path' do
			expect(relative + absolute).to be == absolute
		end
		
		it 'can remove relative parts' do
			expect(absolute + up).to be == described_class['/baz']
		end
	end
	
	describe '#dup' do
		let(:parameters) {Hash.new(x: 10)}
		let(:path) {"foo/bar.html"}
		
		it "can add parameters" do
			copy = subject.dup(nil, parameters)
			expect(copy.parameters).to be == parameters
		end
		
		it "can update path" do
			copy = subject.dup(path)
			
			expect(copy.path).to be == "/foo/bar.html"
		end
	end
	
	context 'empty query string' do
		subject {described_class.new('/', '', nil, {})}
		
		it 'it should not append query string' do
			expect(subject.to_s).to_not include('?')
		end
		
		it 'can add a relative path' do
			result = subject + described_class['foo/bar']
			
			expect(result.to_s).to be == '/foo/bar'
		end
	end
	
	context 'empty fragment' do
		subject {described_class.new('/', nil, '', nil)}
		
		it 'it should not append query string' do
			expect(subject.to_s).to_not include('#')
		end
	end
	
	context Protocol::HTTP::Reference.parse('path with spaces/image.jpg') do
		it "encodes whitespace" do
			expect(subject.to_s).to be == "path%20with%20spaces/image.jpg"
		end
	end
	
	context Protocol::HTTP::Reference.parse('path', array: [1, 2, 3]) do
		it "encodes array" do
			expect(subject.to_s).to be == "path?array[]=1&array[]=2&array[]=3"
		end
	end
	
	context Protocol::HTTP::Reference.parse('path_with_underscores/image.jpg') do
		it "doesn't touch underscores" do
			expect(subject.to_s).to be == "path_with_underscores/image.jpg"
		end
	end
	
	context Protocol::HTTP::Reference.parse('index', 'my name' => 'Bob Dole') do
		it "encodes query" do
			expect(subject.to_s).to be == "index?my%20name=Bob%20Dole"
		end
	end
	
	context Protocol::HTTP::Reference.parse('index#All Your Base') do
		it "encodes fragment" do
			expect(subject.to_s).to be == "index\#All%20Your%20Base"
		end
	end
	
	context Protocol::HTTP::Reference.parse('I/❤️/UNICODE', face: '😀') do
		it "encodes unicode" do
			expect(subject.to_s).to be == "I/%E2%9D%A4%EF%B8%8F/UNICODE?face=%F0%9F%98%80"
		end
	end
	
	context Protocol::HTTP::Reference.parse("foo?bar=10&baz=20", yes: 'no') do
		it "can use existing query parameters" do
			expect(subject.to_s).to be == "foo?bar=10&baz=20&yes=no"
		end
	end
	
	context Protocol::HTTP::Reference.parse('foo#frag') do
		it "can use existing fragment" do
			expect(subject.fragment).to be == "frag"
			expect(subject.to_s).to be == 'foo#frag'
		end
	end
end
