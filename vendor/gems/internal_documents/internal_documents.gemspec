$:.push File.expand_path("../lib", __FILE__)

require "internal_documents/version"

# Absolute minimum gemspec
Gem::Specification.new do |s|
  s.name        = "internal_documents"
  s.version     = InternalDocuments::VERSION
  s.authors     = ["Les Nightingill"]
  s.email       = ["codehacker@comcast.net"]
  s.summary     = "private gem engine for nhridocs app"
end
