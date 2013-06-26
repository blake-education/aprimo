# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aprimo/version'

Gem::Specification.new do |spec|
  spec.name          = "aprimo"
  spec.version       = Aprimo::VERSION
  spec.authors       = ["Brad Wilson"]
  spec.email         = ["brad@lucky-dip.net"]
  spec.description   = %q{A basic wrapper for the Aprimo API}
  spec.summary       = %q{A basic wrapper for the Aprimo API}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency "nokogiri", "~> 1.6.0"
  spec.add_dependency "retriable", "~> 1.3.3"
end
