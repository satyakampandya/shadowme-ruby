require_relative 'lib/shadowme/version'

Gem::Specification.new do |spec|
  spec.name                  = 'shadowme-ruby'
  spec.version               = ShadowMe::VERSION
  spec.authors               = ['Satyakam Pandya']
  spec.email                 = ['satyakampandya@gmail.com']
  spec.homepage              = 'https://github.com/satyakampandya/shadowme-ruby'
  spec.license               = 'MIT'

  spec.summary               = 'Core route sunlight exposure calculation engine for ShadowMe'
  spec.description           = 'A stateless calculation engine that determines optimal ' \
                               'passenger seat side (left/right) to minimize direct ' \
                               'sunlight exposure during a vehicle journey.'
  spec.require_paths         = ['lib']
  spec.required_ruby_version = '>= 3.4.0'

  # Package ONLY the lib files, LICENSE, and README.md into the production gem
  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md']

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/satyakampandya/shadowme-ruby'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/satyakampandya/shadowme-ruby/issues'

  # Runtime dependencies (required by Rails and other clients)
  spec.add_dependency 'dry-validation', '~> 1.10'
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'oj', '~> 3.16'
  spec.add_dependency 'sun_calc', '~> 0.1'
  spec.add_dependency 'zeitwerk', '~> 2.6'
end
