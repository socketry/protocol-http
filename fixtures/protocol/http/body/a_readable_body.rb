# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

module Protocol
	module HTTP
		module Body
			AReadableBody = Sus::Shared("a readable body") do
				with "#read" do
					it "after closing, returns nil" do
						body.close
						
						expect(body.read).to be_nil
					end
				end
				
				with "empty?" do
					it "returns true after closing" do
						body.close
						
						expect(body).to be(:empty?)
					end
				end
			end
		end
	end
end
