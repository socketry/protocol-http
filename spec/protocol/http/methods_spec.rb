# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

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
