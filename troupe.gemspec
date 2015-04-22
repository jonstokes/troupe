# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'troupe/version'

Gem::Specification.new do |spec|
  spec.name          = "troupe"
  spec.version       = Troupe::VERSION
  spec.authors       = ["Jon Stokes"]
  spec.email         = ["jon@jonstokes.com"]

  spec.summary       = %q{These (inter)actors have contracts.}
  spec.description   = %q{This gem layers a contract DSL onto the interactor gem.}
  spec.homepage      = "http://github.com/jonstokes/troupe"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "http://rubygems.com"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'interactor', '~> 3.1'

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
