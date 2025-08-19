# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.

require "protocol/http/reference"

describe Protocol::HTTP::Reference do
	let(:reference) {subject.new}
	
	with "#base" do
		let(:reference) {subject.new("/foo/bar", "foo=bar", "baz", {x: 10})}
		
		it "returns reference with only the path" do
			expect(reference.base).to have_attributes(
				path: be == reference.path,
				parameters: be_nil,
				fragment: be_nil,
			)
		end
	end
	
	with "#+" do
		let(:absolute) {subject["/foo/bar"]}
		let(:relative) {subject["foo/bar"]}
		let(:up) {subject["../baz"]}
		
		it "can add a relative path" do
			expect(reference + relative).to be == absolute
		end
		
		it "can add an absolute path" do
			expect(reference + absolute).to be == absolute
		end
		
		it "can add an absolute path" do
			expect(relative + absolute).to be == absolute
		end
		
		it "can remove relative parts" do
			expect(absolute + up).to be == subject["/baz"]
		end
	end
	
	with "#freeze" do
		it "can freeze reference" do
			expect(reference.freeze).to be_equal(reference)
			expect(reference).to be(:frozen?)
		end
	end
	
	with "#with" do
		it "can nest paths" do
			reference = subject.new("/foo")
			expect(reference.path).to be == "/foo"
			
			nested_resource = reference.with(path: "bar")
			expect(nested_resource.path).to be == "/foo/bar"
		end
		
		it "can update path" do
			copy = reference.with(path: "foo/bar.html")
			expect(copy.path).to be == "/foo/bar.html"
		end
		
		it "can append path components" do
			copy = reference.with(path: "foo/").with(path: "bar/")
			
			expect(copy.path).to be == "/foo/bar/"
		end
		
		it "can append empty path components" do
			copy = reference.with(path: "")
			
			expect(copy.path).to be == reference.path
		end
		
		it "can append parameters" do
			copy = reference.with(parameters: {x: 10})
			
			expect(copy.parameters).to be == {x: 10}
		end
		
		it "can merge parameters" do
			copy = reference.with(parameters: {x: 10}).with(parameters: {y: 20})
			
			expect(copy.parameters).to be == {x: 10, y: 20}
		end
		
		it "can copy parameters" do
			copy = reference.with(parameters: {x: 10}).with(path: "foo")
			
			expect(copy.parameters).to be == {x: 10}
			expect(copy.path).to be == "/foo"
		end
		
		it "can replace path with absolute path" do
			copy = reference.with(path: "foo").with(path: "/bar")
			
			expect(copy.path).to be == "/bar"
		end
		
		it "can replace path with relative path" do
			copy = reference.with(path: "foo").with(path: "../../bar")
			
			expect(copy.path).to be == "/bar"
		end
		
		with "#query" do
			let(:reference) {subject.new("foo/bar/baz.html", "x=10", nil, nil)}
			
			it "can replace query" do
				copy = reference.with(parameters: nil, merge: false)
				
				expect(copy.parameters).to be_nil
				expect(copy.query).to be_nil
			end
			
			it "keeps existing query when merge: false with no parameters" do
				copy = reference.with(fragment: "new-fragment", merge: false)
				
				# Original had no parameters:
				expect(copy.parameters).to be_nil
				
				# Query should be preserved:
				expect(copy.query).to be == "x=10"
				
				# Fragment should be updated:
				expect(copy.fragment).to be == "new-fragment"
			end
		end
		
		with "parameters and query" do
			let(:reference) {subject.new("foo/bar/baz.html", "x=10", nil, {y: 20, z: 30})}
			
			it "keeps existing parameters and query when merge: false with no new parameters" do
				copy = reference.with(fragment: "new-fragment", merge: false)
				
				# Original parameters preserved:
				expect(copy.parameters).to be == {y: 20, z: 30}
				
				# Query should be preserved:
				expect(copy.query).to be == "x=10"
				
				# Fragment should be updated:
				expect(copy.fragment).to be == "new-fragment"
			end
		end
		
		with "relative path" do
			let(:reference) {subject.new("foo/bar/baz.html", nil, nil, nil)}
			
			it "can compute new relative path" do
				copy = reference.with(path: "../index.html", pop: true)
				
				expect(copy.path).to be == "foo/index.html"
			end
			
			it "can compute relative path with more uplevels" do
				copy = reference.with(path: "../../../index.html", pop: true)
				
				expect(copy.path).to be == "../index.html"
			end
		end
	end
	
	with "empty query string" do
		let(:reference) {subject.new("/", "", nil, {})}
		
		it "it should not append query string" do
			expect(reference.to_s).not.to be(:include?, "?")
		end
		
		it "can add a relative path" do
			result = reference + subject["foo/bar"]
			
			expect(result.to_s).to be == "/foo/bar"
		end
	end
	
	with "empty fragment" do
		let(:reference) {subject.new("/", nil, "", nil)}
		
		it "it should not append query string" do
			expect(reference.to_s).not.to be(:include?, "#")
		end
	end
	
	describe Protocol::HTTP::Reference.parse("path with spaces/image.jpg") do
		it "encodes whitespace" do
			expect(subject.to_s).to be == "path%20with%20spaces/image.jpg"
		end
	end
	
	describe Protocol::HTTP::Reference.parse("path", array: [1, 2, 3]) do
		it "encodes array" do
			expect(subject.to_s).to be == "path?array[]=1&array[]=2&array[]=3"
		end
	end
	
	describe Protocol::HTTP::Reference.parse("path_with_underscores/image.jpg") do
		it "doesn't touch underscores" do
			expect(subject.to_s).to be == "path_with_underscores/image.jpg"
		end
	end
	
	describe Protocol::HTTP::Reference.parse("index", "my name" => "Bob Dole") do
		it "encodes query" do
			expect(subject.to_s).to be == "index?my%20name=Bob%20Dole"
		end
	end
	
	describe Protocol::HTTP::Reference.parse("index#All Your Base") do
		it "encodes fragment" do
			expect(subject.to_s).to be == "index\#All%20Your%20Base"
		end
	end
	
	describe Protocol::HTTP::Reference.parse("I/❤️/UNICODE", face: "😀") do
		it "encodes unicode" do
			expect(subject.to_s).to be == "I/%E2%9D%A4%EF%B8%8F/UNICODE?face=%F0%9F%98%80"
		end
	end
	
	describe Protocol::HTTP::Reference.parse("foo?bar=10&baz=20", yes: "no") do
		it "can use existing query parameters" do
			expect(subject.to_s).to be == "foo?bar=10&baz=20&yes=no"
		end
	end
	
	describe Protocol::HTTP::Reference.parse("foo#frag") do
		it "can use existing fragment" do
			expect(subject.fragment).to be == "frag"
			expect(subject.to_s).to be == "foo#frag"
		end
	end
end
