# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2023, by Samuel Williams.
# Copyright, 2022, by Herrick Fang.

require 'protocol/http/header/cookie'

describe Protocol::HTTP::Header::Cookie do
	let(:header) {subject.new(description)}
	let(:cookies) {header.to_h}
	
	with "session=123; secure" do
		it "has named cookie" do
			expect(cookies).to have_keys('session')
			
			session = cookies['session']
			expect(session).to have_attributes(
				name: be == 'session',
				value: be == '123',
			)
			expect(session.directives).to have_keys('secure')
		end
	end

	with "session=123==; secure" do
		it "has named cookie" do
			expect(cookies).to have_keys('session')

			session = cookies['session']
			expect(session).to have_attributes(
				name: be == 'session',
				value: be == '123==',
			)
			expect(session.directives).to have_keys('secure')
		end
	end
end
