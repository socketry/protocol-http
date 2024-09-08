module Protocol
	module HTTP
		module Body
			AReadableBody = Sus::Shared("a readable body") do
				with "#close" do
					it "should close the body" do
						body.close
						expect(body.read).to be_nil
					end
				end
			end
		end
	end
end
