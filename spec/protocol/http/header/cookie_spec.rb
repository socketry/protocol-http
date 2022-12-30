# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2022, by Samuel Williams.
# Copyright, 2022, by Herrick Fang.

require 'protocol/http/header/cookie'

RSpec.describe Protocol::HTTP::Header::Cookie do
	subject {described_class.new(description)}
	let(:cookies) {subject.to_h}
	
	context "session=123; secure" do
		it "has named cookie" do
			expect(cookies).to include('session')
			
			session = cookies['session']
			expect(session).to have_attributes(name: 'session')
			expect(session).to have_attributes(value: '123')
			expect(session.directives).to include('secure')
		end
	end

	context "session=123==; secure" do
		it "has named cookie" do
			expect(cookies).to include('session')

			session = cookies['session']
			expect(session).to have_attributes(name: 'session')
			expect(session).to have_attributes(value: '123==')
			expect(session.directives).to include('secure')
		end
	end
end
