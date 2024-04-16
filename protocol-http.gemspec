# frozen_string_literal: true

require_relative "lib/protocol/http/version"

Gem::Specification.new do |spec|
	spec.name = "protocol-http"
	spec.version = Protocol::HTTP::VERSION
	
	spec.summary = "Provides abstractions to handle HTTP protocols."
	spec.authors = ["Samuel Williams", "Thomas Morgan", "Bruno Sutic", "Herrick Fang", "Bryan Powell", "Dan Olson", "Earlopain", "Genki Takiuchi", "Marcelo Junior", "Olle Jonsson", "Yuta Iwama"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/protocol-http"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/protocol-http/",
		"source_code_uri" => "https://github.com/socketry/protocol-http.git",
	}
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.1"
end
