# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2022, by Samuel Williams.

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
	
	describe '#freeze' do
		it "can freeze reference" do
			expect(subject.freeze).to be subject
			expect(subject).to be_frozen
		end
	end
	
	describe '#dup' do
		let(:parameters) {{x: 10}}
		let(:path) {"foo/bar.html"}
		
		it "can add parameters" do
			copy = subject.dup(nil, parameters)
			expect(copy.parameters).to be == parameters
		end
		
		it "can update path" do
			copy = subject.dup(path)
			
			expect(copy.path).to be == "/foo/bar.html"
		end
		
		it "can append path components" do
			copy = subject.dup("foo/").dup("bar/")
			
			expect(copy.path).to be == "/foo/bar/"
		end
		
		it "can append empty path components" do
			copy = subject.dup("")
			
			expect(copy.path).to be == subject.path
		end
		
		it "can delete last path component" do
			copy = subject.dup("hello").dup("")
			
			expect(copy.path).to be == "/hello/"
		end
		
		it "can merge parameters" do
			subject.parameters = {y: 20}
			copy = subject.dup(nil, parameters, true)
			expect(copy.parameters).to be == {x: 10, y: 20}
		end
		
		it "can replace parameters" do
			subject.parameters = {y: 20}
			copy = subject.dup(nil, parameters, false)
			expect(copy.parameters).to be == parameters
		end
		
		it "can nest path with absolute base" do
			copy = subject.with(path: "foo").with(path: "bar")
			
			expect(copy.path).to be == "/foo/bar"
		end
		
		it "can nest path with relative base" do
			copy = subject.with(path: "foo").with(path: "bar")
			
			expect(copy.path).to be == "/foo/bar"
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
