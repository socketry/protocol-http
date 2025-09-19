# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/http/header/server_timing"
require "sus"

describe Protocol::HTTP::Header::ServerTiming do
	let(:header) {subject.new(description)}
	
	with "empty header" do
		let(:header) {subject.new}
		
		it "should be empty" do
			expect(header.to_s).to be == ""
		end
		
		it "should be an array" do
			expect(header).to be_a(Array)
		end
		
		it "should return empty metrics" do
			expect(header.metrics).to be == []
		end
	end
	
	with "db;dur=53.2" do
		it "can parse metric with duration" do
			metrics = header.metrics
			expect(metrics.size).to be == 1
			expect(metrics.first.name).to be == "db"
			expect(metrics.first.duration).to be == 53.2
			expect(metrics.first.description).to be_nil
		end
	end
	
	with 'cache;desc="Redis lookup"' do
		it "can parse metric with description" do
			metrics = header.metrics
			expect(metrics.size).to be == 1
			expect(metrics.first.name).to be == "cache"
			expect(metrics.first.duration).to be_nil
			expect(metrics.first.description).to be == "Redis lookup"
		end
	end
	
	with 'app;dur=12.7;desc="Application logic"' do
		it "can parse metric with duration and description" do
			metrics = header.metrics
			expect(metrics.first.name).to be == "app"
			expect(metrics.first.duration).to be == 12.7
			expect(metrics.first.description).to be == "Application logic"
		end
	end
	
	with "db;dur=45.3, app;dur=12.7;desc=\"Application logic\", cache;desc=\"Cache miss\"" do
		it "can parse multiple metrics" do
			metrics = header.metrics
			expect(metrics.size).to be == 3
			
			expect(metrics[0].name).to be == "db"
			expect(metrics[0].duration).to be == 45.3
			expect(metrics[0].description).to be_nil
			
			expect(metrics[1].name).to be == "app"
			expect(metrics[1].duration).to be == 12.7
			expect(metrics[1].description).to be == "Application logic"
			
			expect(metrics[2].name).to be == "cache"
			expect(metrics[2].duration).to be_nil
			expect(metrics[2].description).to be == "Cache miss"
		end
	end
	
	with "cache-hit" do
		it "can parse metric with name only" do
			metrics = header.metrics
			expect(metrics.first.name).to be == "cache-hit"
			expect(metrics.first.duration).to be_nil
			expect(metrics.first.description).to be_nil
		end
	end
	
	with "invalid;unknown=param" do
		it "ignores unknown parameters" do
			metrics = header.metrics
			expect(metrics.first.name).to be == "invalid"
			expect(metrics.first.duration).to be_nil
			expect(metrics.first.description).to be_nil
		end
	end
	
	with "invalid-metric-name!" do
		it "raises ParseError for invalid metric name" do
			expect do
				header.metrics
			end.to raise_exception(Protocol::HTTP::Header::ServerTiming::ParseError)
		end
	end
	
	with "#<<" do
		let(:header) {subject.new}
		
		it "can add metrics from string" do
			header << "db;dur=25.5"
			header << "cache;dur=5.2;desc=\"Hit\""
			expect(header.size).to be == 2
			
			metrics = header.metrics
			expect(metrics[0].name).to be == "db"
			expect(metrics[1].name).to be == "cache"
		end
		
		it "can add multiple metrics at once" do
			header << "db;dur=25.5, cache;desc=\"Hit\""
			expect(header.size).to be == 2
			
			metrics = header.metrics
			expect(metrics[0].name).to be == "db"
			expect(metrics[1].name).to be == "cache"
		end
	end
	
	with "inherited Split behavior" do
		let(:header) {subject.new}
		
		it "behaves as an array" do
			header << "db;dur=25.5"
			expect(header.size).to be == 1
			expect(header.first).to be == "db;dur=25.5"
		end
		
		it "can be enumerated" do
			header << "db;dur=25.5, cache;desc=\"Hit\""
			values = []
			header.each {|value| values << value}
			expect(values).to be == ["db;dur=25.5", "cache;desc=\"Hit\""]
		end
		
		it "supports array methods" do
			header << "db;dur=25.5, cache;desc=\"Hit\""
			expect(header.length).to be == 2
			expect(header.empty?).to be == false
		end
	end
	
	with "trailer support" do
		it "should be allowed as a trailer" do
			expect(subject.trailer?).to be == true
		end
	end
	
	with "cache_hit" do
		it "can parse metric with underscore in name" do
			metrics = header.metrics
			expect(metrics.first.name).to be == "cache_hit"
		end
	end
	
	with "test;desc=unquoted-value" do
		it "can parse unquoted description" do
			metrics = header.metrics
			expect(metrics.first.description).to be == "unquoted-value"
		end
	end
	
	with 'test;desc=""' do
		it "can parse empty quoted description" do
			metrics = header.metrics
			expect(metrics.first.description).to be == ""
		end
	end
	
	with "test;dur=123;desc=mixed;unknown=ignored" do
		it "ignores unknown parameters and processes known ones" do
			metrics = header.metrics
			expect(metrics.first.name).to be == "test"
			expect(metrics.first.duration).to be == 123.0
			expect(metrics.first.description).to be == "mixed"
		end
	end
	
	with "test;dur=0" do
		it "can parse zero duration" do
			metrics = header.metrics
			expect(metrics.first.duration).to be == 0.0
		end
	end
	
	with "test;dur=123.456789" do
		it "preserves decimal precision" do
			metrics = header.metrics
			expect(metrics.first.duration).to be == 123.456789
		end
	end
	
	with "Metric class" do
		let(:metric_class) {subject::Metric}
		
		it "can create metric directly" do
			metric = metric_class.new("test", 123.45, "Test metric")
			expect(metric.name).to be == "test"
			expect(metric.duration).to be == 123.45
			expect(metric.description).to be == "Test metric"
			expect(metric.to_s).to be == "test;dur=123.45;desc=\"Test metric\""
		end
		
		it "can create metric with name only" do
			metric = metric_class.new("cache")
			expect(metric.name).to be == "cache"
			expect(metric.duration).to be_nil
			expect(metric.description).to be_nil
			expect(metric.to_s).to be == "cache"
		end
		
		it "can create metric with duration only" do
			metric = metric_class.new("test", 123.45, nil)
			expect(metric.to_s).to be == "test;dur=123.45"
		end
		
		it "can create metric with description only" do
			metric = metric_class.new("test", nil, "description")
			expect(metric.to_s).to be == "test;desc=\"description\""
		end
		
		it "handles nil values correctly" do
			metric = metric_class.new("test", nil, nil)
			expect(metric.to_s).to be == "test"
		end
	end
end