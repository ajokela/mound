$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rabl/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rabl"
  s.version     = Rabl::VERSION
  s.authors     = ["Alex Jokela", "Peter Clark"]
  s.email       = ["ajokela@umn.edu", "pclark@umn.edu"]
  s.homepage    = ""
  s.summary     = "Ruby Abstract Bulk Loader"
  s.description = "Metaprogramming sugar for human-readable data relation building and ingesting"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 3.2.8"
  s.add_dependency "rainbow"
  
  #s.add_development_dependency "sqlite3"
end
