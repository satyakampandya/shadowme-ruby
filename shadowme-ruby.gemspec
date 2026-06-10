Gem::Specification.new do |spec|
  spec.name          = "shadowme-ruby"
  spec.version       = "0.1.0"
  spec.authors       = ["Satyakam Pandya"]
  spec.email         = ["satyakampandya@gmail.com"]
  spec.summary       = "Core route sunlight exposure calculation engine for ShadowMe"
  spec.require_paths = ["lib"]

  # Package all ruby files inside lib and standard documentation files
  spec.files         = Dir["lib/**/*.rb", "README.md"]

  # Runtime dependencies required for the calculation logic
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "oj", "~> 3.16"
  spec.add_dependency "dry-validation", "~> 1.10"
  spec.add_dependency "sun_calc", "~> 1.1"
  spec.add_dependency "zeitwerk", "~> 2.6"
end
