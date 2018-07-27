
require 'http/protocol/http2/framer'

RSpec.shared_examples HTTP::Protocol::HTTP2::Frame do
	let(:io) {StringIO.new}
	
	it "can write frame" do
		subject.write(io)
		
		expect(io.string).to_not be_empty
	end
	
	let(:framer) {HTTP::Protocol::HTTP2::Framer.new(io, {described_class::TYPE => described_class})}
	
	it "can read frame using framer" do
		subject.write(io)
		io.seek(0)
		
		expect(framer.read_frame).to be == subject
	end
end