# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "elastic_whenever/version"

Gem::Specification.new do |spec|
  spec.name          = "elastic_whenever"
  spec.version       = ElasticWhenever::VERSION
  spec.authors       = ["Kazuma Watanabe"]
  spec.email         = ["watassbass@gmail.com"]

  spec.summary       = %q{Manage ECS Scheduled Tasks like Whenever}
  spec.description   = %q{Manage ECS Scheduled Tasks like Whenever}
  spec.homepage      = "https://github.com/wata727/elastic_whenever"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "aws-sdk-ecs", "~> 1.0"
  spec.add_dependency "aws-sdk-cloudwatchevents", "~> 1.5"
  spec.add_dependency "aws-sdk-iam", "~> 1.0"
  spec.add_dependency "chronic", "~> 0.10"
  spec.add_dependency "retryable", "~> 3.0"
end
