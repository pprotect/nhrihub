$:.push File.expand_path("../lib", __FILE__)

require "excess/version"

Gem::Specification.new do |s|
  s.name        = "excess"
  s.version     = Excess::VERSION
  s.authors     = ["Les Nightingill"]
  s.email       = ["info@mustardseeddatabase.org"]
  s.homepage    = "http://www.mustardseeddatabase.org"
  s.summary     = "Lightweight Rails engine to emit Excel documents"
  s.description = "Mounts as an engine in a Rails application"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 6.0.1"
  s.add_dependency "haml"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "capybara"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "byebug"
end
