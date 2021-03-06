# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gremlin/version'

Gem::Specification.new do |spec|
  spec.name          = "gremlin"
  spec.version       = Gremlin::VERSION
  spec.authors       = ['Tom Dalling']
  spec.email         = ['tom' + '@' + 'tomdalling.com']

  spec.summary       = %q{Trying to get Opal + web game dev to play together nicely}
  spec.homepage      = 'https://github.com/tomdalling/gremlin'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'opal', '~> 0.7.1'
  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'guard', '~> 2.12.5'
  spec.add_development_dependency 'guard-rake', '~> 1.0.0'
  spec.add_development_dependency 'guard-livereload', '~> 2.4.0'
end
