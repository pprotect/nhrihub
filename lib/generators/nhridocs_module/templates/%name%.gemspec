$:.push File.expand_path("../lib", __FILE__)

require "<%= name %>/version"

# Absolute minimum gemspec
Gem::Specification.new do |s|
  s.name        = "<%= name %>"
  s.version     = <%= camelized %>::VERSION
  s.authors     = ["write your name here"]
  s.email       = ["write your email address here"]
  s.summary     = "private gem engine for nhridocs app"
end
