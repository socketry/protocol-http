# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require 'protocol/http/body/head'

RSpec.describe Protocol::HTTP::Body::Head do
	context "with zero length" do
		subject(:body) {described_class.new(0)}
		
		it {is_expected.to be_empty}
		
		describe '#join' do
			subject {body.join}
			
			it {is_expected.to be_nil}
		end
	end
	
	context "with non-zero length" do
		subject(:body) {described_class.new(1)}
		
		it {is_expected.to be_empty}
		
		describe '#read' do
			subject {body.read}
			it {is_expected.to be_nil}
		end
		
		describe '#join' do
			subject {body.join}
			
			it {is_expected.to be_nil}
		end
	end
	
	describe '.for' do
		let(:body) {double}
		subject {described_class.for(body)}
		
		it "captures length and closes existing body" do
			expect(body).to receive(:length).and_return(1)
			expect(body).to receive(:close)
			
			expect(subject).to have_attributes(length: 1)
			
			subject.close
		end
	end
end
