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

RSpec.describe Protocol::HTTP::Headers do
	let(:fields) do
		[
			['Content-Type', 'text/html'],
			['Set-Cookie', 'hello=world'],
			['Accept', '*/*'],
			['Set-Cookie', 'foo=bar'],
			['Connection', 'Keep-Alive']
		]
	end
	
	before(:each) do
		fields&.each do |name, value|
			subject.add(name, value)
		end
	end
	
	describe '#freeze' do
		it "can't modify frozen headers" do
			subject.freeze
			
			expect(subject.fields).to be == fields
			expect(subject.fields).to be_frozen
			expect(subject.to_h).to be_frozen
		end
	end
	
	describe '#dup' do
		it "should not modify source object" do
			headers = subject.dup
			
			headers['field'] = 'value'
			
			expect(subject).to_not include('field')
		end
	end
	
	describe '#empty?' do
		it "shouldn't be empty" do
			expect(subject).to_not be_empty
		end
	end
	
	describe '#fields' do
		it 'should add fields in order' do
			expect(subject.fields).to be == fields
		end
		
		it 'can enumerate fields' do
			subject.each.with_index do |field, index|
				expect(field).to be == fields[index]
			end
		end
	end
	
	describe '#to_h' do
		it 'should generate array values for duplicate keys' do
			expect(subject.to_h['set-cookie']).to be == ['hello=world', 'foo=bar']
		end
	end
	
	describe '#[]' do
		it 'can lookup fields' do
			expect(subject['content-type']).to be == 'text/html'
		end
	end
	
	describe '#[]=' do
		it 'can add field' do
			subject['Content-Length'] = 1
			
			expect(subject.fields.last).to be == ['Content-Length', 1]
			expect(subject['content-length']).to be == 1
		end
		
		it 'can add field with indexed hash' do
			expect(subject.to_h).to_not be_empty
			
			subject['Content-Length'] = 1
			expect(subject['content-length']).to be == 1
		end
	end
	
	describe '#add' do
		it 'can add field' do
			subject.add('Content-Length', 1)
			
			expect(subject.fields.last).to be == ['Content-Length', 1]
			expect(subject['content-length']).to be == 1
		end
	end
	
	describe '#set' do
		it 'can replace an existing field' do
			subject.add('accept-encoding', 'gzip,deflate')
			
			subject.set('accept-encoding', 'gzip')
			
			expect(subject['accept-encoding']).to be == ['gzip']
		end
	end
	
	describe '#extract' do
		it "can extract key's that don't exist" do
			expect(subject.extract('foo')).to be_empty
		end
		
		it 'can extract single key' do
			expect(subject.extract('content-type')).to be == [['Content-Type', 'text/html']]
		end
	end
	
	describe '#==' do
		it "can compare with array" do
			expect(subject).to be == fields
		end
		
		it "can compare with itself" do
			expect(subject).to be == subject
		end
		
		it "can compare with hash" do
			expect(subject).to_not be == {}
		end
	end
	
	describe '#delete' do
		it 'can delete case insensitive fields' do
			expect(subject.delete('content-type')).to be == 'text/html'
			
			expect(subject.fields).to be == fields[1..-1]
		end
		
		it 'can delete non-existant fields' do
			expect(subject.delete('transfer-encoding')).to be_nil
		end
	end
	
	describe '#merge' do
		it "can merge content-length" do
			subject.merge!('content-length' => 2)
			
			expect(subject['content-length']).to be == 2
		end
	end
	
	describe '#trailer!' do
		it "can add trailer" do
			subject.add('trailer', 'etag')
			
			trailer = subject.trailer!
			
			subject.add('etag', 'abcd')
			
			expect(trailer.to_h).to be == {'etag' => 'abcd'}
		end
	end
	
	describe '#trailer' do
		it "can enumerate trailer" do
			subject.add('trailer', 'etag')
			subject.trailer!
			subject.add('etag', 'abcd')
			
			expect(subject.trailer.to_h).to be == {'etag' => 'abcd'}
		end
	end
	
	describe '#flatten!' do
		it "can flatten trailer" do
			subject.add('trailer', 'etag')
			trailer = subject.trailer!
			subject.add('etag', 'abcd')
			
			subject.flatten!
			
			expect(subject).to_not include('trailer')
			expect(subject).to include('etag')
		end
	end
	
	describe '#flatten' do
		it "can flatten trailer" do
			subject.add('trailer', 'etag')
			trailer = subject.trailer!
			subject.add('etag', 'abcd')
			
			copy = subject.flatten
			
			expect(subject).to include('trailer')
			expect(subject).to include('etag')
			
			expect(copy).to_not include('trailer')
			expect(copy).to include('etag')
		end
	end
	
	describe 'set-cookie' do
		it "can extract parsed cookies" do
			expect(subject['set-cookie']).to be_kind_of(Protocol::HTTP::Header::Cookie)
		end
	end
	
	describe 'connection' do
		it "can extract connection options" do
			expect(subject['connection']).to be_kind_of(Protocol::HTTP::Header::Connection)
		end
		
		it "should normalize to lower case" do
			expect(subject['connection']).to be == ['keep-alive']
		end
	end
end
