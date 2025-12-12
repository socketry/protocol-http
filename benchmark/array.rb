# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "sus/fixtures/benchmark"

describe "Array initialization" do
	include Sus::Fixtures::Benchmark
	
	let(:source_array) {["value1", "value2", "value3", "value4", "value5"]}
	
	measure "Array.new(array)" do |repeats|
		repeats.times do
			Array.new(source_array)
		end
	end
	
	measure "Array.new.concat(array)" do |repeats|
		repeats.times do
			array = Array.new
			array.concat(source_array)
		end
	end
end

