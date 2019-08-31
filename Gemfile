source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~>6.0.0.rc1'
gem 'activestorage'

gem 'bootsnap', :require => false

# Use postgresql as the database for Active Record
gem 'pg'
#gem 'mysql'
#gem 'mysql2'
# Use SCSS for stylesheets
gem 'sass-rails'#, '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'#, '~> 4.0.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer',  "~> 0.12.3", platforms: :ruby

gem 'i18n'

gem 'rb-readline'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
#gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
##gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
##gem 'sdoc', '~> 0.4.0',          group: :doc


# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

# to control crontab from ruby
gem 'whenever', :require => false

# ruby configuration of content security policy
gem 'secure_headers', :git => 'https://github.com/twitter/secureheaders', :branch => 'master', :require => 'secure_headers'

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  # Use Capistrano for deployment
  gem 'capistrano-rails'
  gem 'capistrano', '~>3.8.1'
  # capistrano add-ons
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-faster-assets'
  gem 'capistrano-yarn'
  # specify higher rev than required by capistrano in order to get
  # fixed connection pooling and faster deploys
  gem 'sshkit', '~> 1.5'
  gem 'jekyll'
  gem 'jekyll-theme-tactile'
end

gem 'haml-rails'
gem 'haml', '~> 5.1.0'
gem 'html2haml', '~> 2.2.0'

group :development, :test, :jstest do
  gem 'rspec-rails'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'database_cleaner', '~>1.6.1'
  gem 'teaspoon'
  gem 'teaspoon-mocha'
  gem 'magic_lamp'
  gem 'simplecov', :require => false
  gem 'irb'
  gem 'launchy'
  gem 'byebug'
  gem 'puma'
  gem "sinatra", git: "https://github.com/sinatra/sinatra.git" #, :ref => "285275b42fa1bf096a5c9559b6cead2f31b65b66" # for rack 2 compatibility as required for rails5
end
gem 'js-routes'
gem 'bootstrap-sass'
gem 'simple-navigation-bootstrap'
gem 'font-awesome-sass', '=4.7.0'
#gem 'simple-navigation', '~> 4.0.3' seems to have some problems with simple-navigation-bootstrap
gem 'simple-navigation', '~> 3.14.0'
gem 'factory_bot_rails', '~> 4.0'
gem 'faker'

gem 'tzinfo-data' # so that we use the ruby tzinfo vs what is installed on the machine e.g. /usr/share/zoneinfo

gem 'acme_plugin', "~> 0.0.10"

gem "refile", :git => "https://github.com/refile/refile.git", :ref => "d7a42", require: "refile/rails" # for rails5 compatibility
gem "rack", git: "https://github.com/rack/rack.git" # also for sinatra 2.0.0-alpha support
gem "rack-protection" #, git: "https://github.com/sinatra/rack-protection.git"
gem "rails-settings-cached", '~> 0.4.2'
gem "underscore-rails"
gem "capistrano-linked-files"
gem "message_block", git: "https://github.com/lazylester/message_block.git"
gem "surus", git: "https://github.com/asiapacificforum/surus.git", :ref => "36cb18a" # postgres direct to json
gem "aws-sdk", "~> 2"
gem "rack-attack"
gem "rack-mini-profiler", '~>1.0.2'
gem "flamegraph"
gem "stackprof", :require => false
gem "webpacker", '~> 4.0.7'
gem "bulk_cache_fetcher" # used in complaints module

### NHRI Modules:
gem 'authengine', :path => 'vendor/gems/authengine'
gem 'strategic_plans', :path => 'vendor/gems/strategic_plans'
gem 'media', :path => 'vendor/gems/media'
gem 'nhri', :path => 'vendor/gems/nhri'
gem 'complaints', :path => 'vendor/gems/complaints'
gem 'projects', :path => 'vendor/gems/projects'
gem 'internal_documents', :path => 'vendor/gems/internal_documents'
gem 'dashboard', :path => 'vendor/gems/dashboard'
gem 'strategic_plan_reporter', :path => 'vendor/gems/strategic_plan_reporter'
gem 'complaint_reporter', :path => 'vendor/gems/complaint_reporter'
gem 'issues_reporter', :path => 'vendor/gems/issues_reporter'
