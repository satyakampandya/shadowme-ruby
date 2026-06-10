require_relative 'lib/shadowme/version'

Gem::Specification.new do |spec|
  spec.name          = 'shadowme-ruby'
  spec.version       = ShadowMe::VERSION
  spec.authors       = ['Satyakam Pandya']
  spec.email         = ['satyakampandya@gmail.com']
  spec.summary       = 'Core route sunlight exposure calculation engine for ShadowMe'
  spec.require_paths = ['lib']

  # Package ONLY the lib files and README.md into the production gem
  spec.files         = Dir['lib/**/*.rb', 'README.md']
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Runtime dependencies (required by Rails and other clients)
  spec.add_dependency 'dry-validation', '~> 1.10'
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'oj', '~> 3.16'
  spec.add_dependency 'sun_calc', '~> 0.1'
  spec.add_dependency 'zeitwerk', '~> 2.6'
end
