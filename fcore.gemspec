# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'fcore'
  spec.version       = '0.0.1'
  spec.licenses      = ['MIT']
  spec.authors       = ['Joe Osburn']
  spec.email         = ['joe@jnodev.com']

  spec.summary       = 'FreedomCore is a simple reactor core.'
  spec.homepage      = 'https://github.com/joeosburn/fcore'
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']
  spec.test_files = Dir['spec/**/*']
end
