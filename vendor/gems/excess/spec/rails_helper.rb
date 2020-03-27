# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] = 'test'
#require 'spec_helper' # not required here as it's in .rspec

require File.expand_path('../dummy/config/environment.rb', __FILE__)
require 'rspec/rails'
#require File.expand_path('../helpers/application_helpers',__FILE__)

$:.unshift File.expand_path '../helpers', __FILE__
$:.unshift File.expand_path '../shared_behaviours', __FILE__
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # 
  # for reasons I don't fully understand, transactional fixtures cause test failures
  # when using the capybara selenium driver, so disable them here
  # and use database cleaner instead!
  #config.use_transactional_fixtures = true
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  #config.infer_spec_type_from_file_location!

  #config.include ApplicationHelpers
end

