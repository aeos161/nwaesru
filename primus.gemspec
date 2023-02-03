Gem::Specification.new do |config|
  config.name = "primus"
  config.version = "0.0.0"
  config.summary = "Assist in Solving LP"
  config.description = "Re-useable algorithms"
  config.authors = ["Chris Woodford"]
  config.email = "chris.woodford@gmail.com"
  config.files = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  config.require_path = "lib"
  config.homepage = "https://rubygems.org/gems/primus"
  config.license = "MIT"

  config.add_runtime_dependency "linguo"

  config.add_development_dependency "simplecov", "~> 0.2"
  config.add_development_dependency "bundler", "~> 2.1"
  config.add_development_dependency "numeric_inverse", "~> 0.1"
  config.add_development_dependency "pry", "~> 0.14"
  config.add_development_dependency "psych", "~> 4.0"
  config.add_development_dependency "rake", "~> 13.0"
  config.add_development_dependency "rspec", "~> 3.10"
end
