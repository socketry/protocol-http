# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'protocol/http/reference'

describe Protocol::HTTP::Reference do
	let(:reference) {subject.new}
	
	with '#+' do
		let(:absolute) {subject['/foo/bar']}
		let(:relative) {subject['foo/bar']}
		let(:up) {subject['../baz']}
		
		it 'can add a relative path' do
			expect(reference + relative).to be == absolute
		end
		
		it 'can add an absolute path' do
			expect(reference + absolute).to be == absolute
		end
		
		it 'can add an absolute path' do
			expect(relative + absolute).to be == absolute
		end
		
		it 'can remove relative parts' do
			expect(absolute + up).to be == subject['/baz']
		end
	end
	
	with '#freeze' do
		it "can freeze reference" do
			expect(reference.freeze).to be_equal(reference)
			expect(reference).to be(:frozen?)
		end
	end
	
	with '#dup' do
		let(:parameters) {{x: 10}}
		let(:path) {"foo/bar.html"}
		
		it "can add parameters" do
			copy = reference.dup(nil, parameters)
			expect(copy.parameters).to be == parameters
		end
		
		it "can update path" do
			copy = reference.dup(path)
			expect(copy.path).to be == "/foo/bar.html"
		end
		
		it "can append path components" do
			copy = reference.dup("foo/").dup("bar/")
			
			expect(copy.path).to be == "/foo/bar/"
		end
		
		it "can append empty path components" do
			copy = reference.dup("")
			
			expect(copy.path).to be == reference.path
		end
		
		it "can delete last path component" do
			copy = reference.dup("hello").dup("")
			
			expect(copy.path).to be == "/hello/"
		end
		
		it "can merge parameters" do
			reference.parameters = {y: 20}
			copy = reference.dup(nil, parameters, true)
			expect(copy.parameters).to be == {x: 10, y: 20}
		end
		
		it "can replace parameters" do
			reference.parameters = {y: 20}
			copy = reference.dup(nil, parameters, false)
			expect(copy.parameters).to be == parameters
		end
		
		it "can nest path with absolute base" do
			copy = reference.with(path: "foo").with(path: "bar")
			
			expect(copy.path).to be == "/foo/bar"
		end
		
		it "can nest path with relative base" do
			copy = reference.with(path: "foo").with(path: "bar")
			
			expect(copy.path).to be == "/foo/bar"
		end
	end
	
	with 'empty query string' do
		let(:reference) {subject.new('/', '', nil, {})}
		
		it 'it should not append query string' do
			expect(reference.to_s).not.to be(:include?, '?')
		end
		
		it 'can add a relative path' do
			result = reference + subject['foo/bar']
			
			expect(result.to_s).to be == '/foo/bar'
		end
	end
	
	with 'empty fragment' do
		let(:reference) {subject.new('/', nil, '', nil)}
		
		it 'it should not append query string' do
			expect(reference.to_s).not.to be(:include?, '#')
		end
	end
	
	describe Protocol::HTTP::Reference.parse('path with spaces/image.jpg') do
		it "encodes whitespace" do
			expect(subject.to_s).to be == "path%20with%20spaces/image.jpg"
		end
	end
	
	describe Protocol::HTTP::Reference.parse('path', array: [1, 2, 3]) do
		it "encodes array" do
			expect(subject.to_s).to be == "path?array[]=1&array[]=2&array[]=3"
		end
	end
	
	describe Protocol::HTTP::Reference.parse('path_with_underscores/image.jpg') do
		it "doesn't touch underscores" do
			expect(subject.to_s).to be == "path_with_underscores/image.jpg"
		end
	end
	
	describe Protocol::HTTP::Reference.parse('index', 'my name' => 'Bob Dole') do
		it "encodes query" do
			expect(subject.to_s).to be == "index?my%20name=Bob%20Dole"
		end
	end
	
	describe Protocol::HTTP::Reference.parse('index#All Your Base') do
		it "encodes fragment" do
			expect(subject.to_s).to be == "index\#All%20Your%20Base"
		end
	end
	
	describe Protocol::HTTP::Reference.parse('I/❤️/UNICODE', face: '😀') do
		it "encodes unicode" do
			expect(subject.to_s).to be == "I/%E2%9D%A4%EF%B8%8F/UNICODE?face=%F0%9F%98%80"
		end
	end
	
	describe Protocol::HTTP::Reference.parse("foo?bar=10&baz=20", yes: 'no') do
		it "can use existing query parameters" do
			expect(subject.to_s).to be == "foo?bar=10&baz=20&yes=no"
		end
	end
	
	describe Protocol::HTTP::Reference.parse('foo#frag') do
		it "can use existing fragment" do
			expect(subject.fragment).to be == "frag"
			expect(subject.to_s).to be == 'foo#frag'
		end
	end
end
