# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

def external
	require 'bundler'
	
	Bundler.with_unbundled_env do
		clone_and_test("protocol-http1")
		clone_and_test("protocol-http2")
		clone_and_test("async-websocket")
		clone_and_test("async-http")
		clone_and_test("async-rest")
		clone_and_test("falcon")
	end
end

private

def clone_and_test(name)
	path = "external/#{name}"
	
	unless File.exist?(path)
		system("git", "clone", "https://git@github.com/socketry/#{name}", path)
	end
	
	gemfile = [
		File.join(path, "gems.rb"),
		File.join(path, "Gemfile"),
	].find{|path| File.exist?(path)}
	
	system("git", "checkout", "-f", File.basename(gemfile), chdir: path)
	
	File.open(gemfile, "a") do |file|
		file.puts('', 'gem "protocol-http", path: "../../"')
	end
	
	system("bundle install && bundle exec rspec", chdir: path)
end
