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

  config.add_development_dependency "bundler"
  config.add_development_dependency "pry"
  config.add_development_dependency "rake"
  config.add_development_dependency "rspec"
end
