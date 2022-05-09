require_relative "lib/searchjoy/version"

Gem::Specification.new do |spec|
  spec.name          = "searchjoy"
  spec.version       = Searchjoy::VERSION
  spec.summary       = "Search analytics made easy"
  spec.homepage      = "https://github.com/ankane/searchjoy"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{app,config,lib,licenses}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 2.6"

  spec.add_dependency "chartkick", ">= 3.2"
  spec.add_dependency "groupdate", ">= 3"
  spec.add_dependency "activerecord", ">= 5.2"
end
