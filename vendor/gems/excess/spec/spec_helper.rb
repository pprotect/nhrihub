ENV["RAILS_ENV"] = "test"
require File.expand_path("../dummy/config/environment.rb",  __FILE__)

require 'rspec/rails'
require 'capybara/rspec'
require 'ruby-debug'

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end

