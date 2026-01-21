# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require "protocol/http/middleware"
require "protocol/http/middleware/builder"
require "tempfile"

describe Protocol::HTTP::Middleware::Builder do
	it "can make an app" do
		app = Protocol::HTTP::Middleware.build do
			run Protocol::HTTP::Middleware::HelloWorld
		end
		
		expect(app).to be_equal(Protocol::HTTP::Middleware::HelloWorld)
	end
	
	it "defaults to not found" do
		app = Protocol::HTTP::Middleware.build do
		end
		
		expect(app).to be_equal(Protocol::HTTP::Middleware::NotFound)
	end
	
	it "can instantiate middleware" do
		app = Protocol::HTTP::Middleware.build do
			use Protocol::HTTP::Middleware
		end
		
		expect(app).to be_a(Protocol::HTTP::Middleware)
	end
	
	it "provides the builder as an argument" do
		current_self = self
		
		app = Protocol::HTTP::Middleware.build do |builder|
			builder.use Protocol::HTTP::Middleware
			
			expect(self).to be_equal(current_self)
		end
		
		expect(app).to be_a(Protocol::HTTP::Middleware)
	end
	
	it "can initialize with custom default app" do
		builder = Protocol::HTTP::Middleware::Builder.new(Protocol::HTTP::Middleware::Okay)
		
		expect(builder.to_app).to be_equal(Protocol::HTTP::Middleware::Okay)
	end
	
	it "can build without block" do
		builder = Protocol::HTTP::Middleware::Builder.new
		result = builder.build
		
		expect(result).to be_equal(builder)
		expect(builder.to_app).to be_equal(Protocol::HTTP::Middleware::NotFound)
	end
	
	it "can build with zero-arity block using instance_exec" do
		builder = Protocol::HTTP::Middleware::Builder.new
		
		builder.build do
			use Protocol::HTTP::Middleware
		end
		
		expect(builder.to_app).to be_a(Protocol::HTTP::Middleware)
	end
	
	it "can use middleware with arguments" do
		middleware_class = Class.new(Protocol::HTTP::Middleware) do
			def initialize(app, argument1, argument2)
				super(app)
				@argument1 = argument1
				@argument2 = argument2
			end
			
			attr :argument1, :argument2
		end
		
		builder = Protocol::HTTP::Middleware::Builder.new(Protocol::HTTP::Middleware::Okay)
		builder.use(middleware_class, "test1", "test2")
		
		app = builder.to_app
		expect(app).to be_a(middleware_class)
		expect(app.argument1).to be == "test1"
		expect(app.argument2).to be == "test2"
	end
	
	it "can use middleware with options" do
		middleware_class = Class.new(Protocol::HTTP::Middleware) do
			def initialize(app, option1:, option2:)
				super(app)
				@option1 = option1
				@option2 = option2
			end
			
			attr :option1, :option2
		end
		
		builder = Protocol::HTTP::Middleware::Builder.new(Protocol::HTTP::Middleware::Okay)
		builder.use(middleware_class, option1: "value1", option2: "value2")
		
		app = builder.to_app
		expect(app).to be_a(middleware_class)
		expect(app.option1).to be == "value1"
		expect(app.option2).to be == "value2"
	end
	
	it "can use middleware with block" do
		middleware_class = Class.new(Protocol::HTTP::Middleware) do
			def initialize(app, &block)
				super(app)
				@block = block
			end
			
			attr :block
		end
		
		block_called = false
		builder = Protocol::HTTP::Middleware::Builder.new(Protocol::HTTP::Middleware::Okay)
		builder.use(middleware_class) do
			block_called = true
		end
		
		app = builder.to_app
		expect(app).to be_a(middleware_class)
		expect(app.block).to be_a(Proc)
		app.block.call
		expect(block_called).to be == true
	end
	
	it "can run to set default app" do
		builder = Protocol::HTTP::Middleware::Builder.new
		builder.run(Protocol::HTTP::Middleware::Okay)
		
		expect(builder.to_app).to be_equal(Protocol::HTTP::Middleware::Okay)
	end
	
	it "can chain multiple middleware" do
		middleware1 = Class.new(Protocol::HTTP::Middleware) do
			def initialize(app)
				super(app)
				@name = "middleware1"
			end
			
			attr :name
		end
		
		middleware2 = Class.new(Protocol::HTTP::Middleware) do
			def initialize(app)
				super(app)
				@name = "middleware2"
			end
			
			attr :name
		end
		
		builder = Protocol::HTTP::Middleware::Builder.new(Protocol::HTTP::Middleware::Okay)
		builder.use(middleware1)
		builder.use(middleware2)
		
		app = builder.to_app
		# Middleware are reversed, so first added becomes outermost
		expect(app).to be_a(middleware1)
		expect(app.delegate).to be_a(middleware2)
		expect(app.delegate.delegate).to be_equal(Protocol::HTTP::Middleware::Okay)
	end
	
	it "can convert to app directly" do
		builder = Protocol::HTTP::Middleware::Builder.new(Protocol::HTTP::Middleware::HelloWorld)
		
		app = builder.to_app
		expect(app).to be_equal(Protocol::HTTP::Middleware::HelloWorld)
	end
	
	it "can load middleware from file" do
		temp_file = Tempfile.new(["middleware", ".rb"])
		temp_file.write(<<~RUBY)
			use Protocol::HTTP::Middleware
			run Protocol::HTTP::Middleware::HelloWorld
		RUBY
		temp_file.close
		
		app = Protocol::HTTP::Middleware.load(temp_file.path)
		
		expect(app).to be_a(Protocol::HTTP::Middleware)
		expect(app.delegate).to be_equal(Protocol::HTTP::Middleware::HelloWorld)
		
	ensure
		temp_file&.unlink
	end
	
	it "can load middleware from file with block" do
		temp_file = Tempfile.new(["middleware", ".rb"])
		temp_file.write(<<~RUBY)
			use Protocol::HTTP::Middleware
		RUBY
		temp_file.close
		
		app = Protocol::HTTP::Middleware.load(temp_file.path) do
			run Protocol::HTTP::Middleware::HelloWorld
		end
		
		expect(app).to be_a(Protocol::HTTP::Middleware)
		expect(app.delegate).to be_equal(Protocol::HTTP::Middleware::HelloWorld)
		
	ensure
		temp_file&.unlink
	end
end
