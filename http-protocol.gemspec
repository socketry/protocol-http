
require_relative "lib/http/protocol/version"

Gem::Specification.new do |spec|
	spec.name          = "http-protocol"
	spec.version       = HTTP::Protocol::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]

	spec.summary       = "Provides abstractions to handle HTTP1 and HTTP2 protocols."
	spec.homepage      = "https://github.com/socketry/http-protocol"

	spec.files         = `git ls-files -z`.split("\x0").reject do |f|
		f.match(%r{^(test|spec|features)/})
	end

	spec.require_paths = ["lib"]

	spec.add_dependency "http-hpack", "~> 0.1.0"

	spec.add_development_dependency "bundler", "~> 1.16"
	spec.add_development_dependency "rake", "~> 10.0"
	spec.add_development_dependency "rspec", "~> 3.0"
end
