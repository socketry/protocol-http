# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2024, by Samuel Williams.

source "https://rubygems.org"

# Specify your gem's dependencies in protocol-http.gemspec
gemspec

group :maintenance, optional: true do
	gem "bake-modernize"
	gem "bake-gem"
	
	gem "utopia-project", "~> 0.18"
	gem "bake-releases"
end

group :test do
	gem "covered"
	gem "sus"
	gem "decode"
	gem "rubocop"
	
	gem "bake-test"
	gem "bake-test-external"
end
