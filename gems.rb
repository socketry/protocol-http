# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.

source "https://rubygems.org"

# Specify your gem's dependencies in protocol-http.gemspec
gemspec

# gem "async-http", path: "../async-http"

group :maintenance, optional: true do
	gem "bake-modernize"
	gem "bake-gem"
	gem "bake-releases"
	
	gem "agent-context"
	
	gem "utopia-project", "~> 0.18"
end

group :test do
	gem "covered"
	gem "sus"
	gem "decode"
	
	gem "rubocop"
	gem "rubocop-socketry"
	
	gem "sus-fixtures-async"
	gem "sus-fixtures-benchmark"
	
	gem "bake-test"
	gem "bake-test-external"
end
