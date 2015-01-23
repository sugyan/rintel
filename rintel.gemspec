# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rintel/version'

Gem::Specification.new do |spec|
  spec.name          = "rintel"
  spec.version       = Rintel::VERSION
  spec.authors       = ["sugyan"]
  spec.email         = ["sugi1982@gmail.com"]
  spec.summary       = %q{Ingress Intel Map client}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "mechanize", "~> 2.7.3"
end
