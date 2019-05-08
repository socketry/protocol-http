
require_relative "lib/protocol/http/version"

Gem::Specification.new do |spec|
	spec.name          = "protocol-http"
	spec.version       = Protocol::HTTP::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]
	
	spec.summary       = "Provides abstractions to handle HTTP protocols."
	spec.homepage      = "https://github.com/socketry/protocol-http"
	spec.license       = "MIT"
	
	spec.files         = `git ls-files -z`.split("\x0").reject do |f|
		f.match(%r{^(test|spec|features)/})
	end
	
	spec.required_ruby_version = '>= 2.4.0'
	
	spec.require_paths = ["lib"]
	
	spec.add_development_dependency "covered"
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "rake", "~> 10.0"
	spec.add_development_dependency "rspec", "~> 3.0"
end
