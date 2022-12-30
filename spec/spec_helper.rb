# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2022, by Samuel Williams.

require 'async/rspec'
require 'covered/rspec'

RSpec.shared_context 'docstring as description' do
	let(:description) {self.class.metadata.fetch(:description_args).first}
end

RSpec.configure do |config|
	# Enable flags like --only-failures and --next-failure
	config.example_status_persistence_file_path = ".rspec_status"
	
	# Disable RSpec exposing methods globally on `Module` and `main`
	config.disable_monkey_patching!
	
	config.include_context 'docstring as description'
	
	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
