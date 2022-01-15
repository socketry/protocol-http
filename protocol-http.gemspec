# frozen_string_literal: true

require_relative "lib/protocol/http/version"

Gem::Specification.new do |spec|
	spec.name = "protocol-http"
	spec.version = Protocol::HTTP::VERSION
	
	spec.summary = "Provides abstractions to handle HTTP protocols."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.homepage = "https://github.com/socketry/protocol-http"
	
	spec.files = Dir.glob('{lib}/**/*', File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 2.5"
	
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "rspec"
end
