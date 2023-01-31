# frozen_string_literal: true

require_relative "lib/protocol/http/version"

Gem::Specification.new do |spec|
	spec.name = "protocol-http"
	spec.version = Protocol::HTTP::VERSION
	
	spec.summary = "Provides abstractions to handle HTTP protocols."
	spec.authors = ["Samuel Williams", "Herrick Fang", "Bruno Sutic", "Bryan Powell", "Dan Olson", "Olle Jonsson", "Yuta Iwama"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/protocol-http"
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 2.5"
	
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "sus"
end
