# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

module Protocol
	module HTTP
		module Body
			AWritableBody = Sus::Shared("a readable body") do
				with "#read" do
					it "after closing the write end, returns all chunks" do
						body.write("Hello ")
						body.write("World!")
						body.close_write
						
						expect(body.read).to be == "Hello "
						expect(body.read).to be == "World!"
						expect(body.read).to be_nil
					end
				end
				
				with "empty?" do
					it "returns false before writing" do
						expect(body).not.to be(:empty?)
					end
					
					it "returns true after all chunks are consumed" do
						body.write("Hello")
						body.close_write
						
						expect(body).not.to be(:empty?)
						expect(body.read).to be == "Hello"
						expect(body.read).to be_nil
						
						expect(body).to be(:empty?)
					end
				end
			end
		end
	end
end
