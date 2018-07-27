source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in http-protocol.gemspec
gemspec

group :test do
	gem 'covered', require: 'covered/rspec' if RUBY_VERSION >= "2.6.0"
end
