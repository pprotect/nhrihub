Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  config.load_defaults "6.0" # enables zeitwerk mode in CRuby

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  #config.cache_store = :file_store, Rails.root.join('tmp', 'devcache')

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  #config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = true

  # Raise error on unpermitted parameters.
  config.action_controller.action_on_unpermitted_parameters = :raise

  # Disable quiet_assets gem and allow asset requests to be reported in the log
  # config.quiet_assets = false

  config.log_tags = [ :remote_ip, ->(req){
    if user_id = TaggedLogger.extract_user_id_from_request(req)
      user_id.to_s
    else
      "anon"
    end
  } ]

  # autoload vendor/gems files for every request
  config.autoload_paths += Dir.glob(Rails.root.join("vendor", "gems", "**", "app", "**", "{models,views,controllers}"))
  config.autoload_paths += Dir.glob(Rails.root.join( "app", "domain_models"))
  config.autoload_paths += Dir.glob(Rails.root.join( "app", "domain_models", "report_utilities"))
  config.autoload_paths += Dir.glob(Rails.root.join( "**", "app", "domain_models"))


  # teaspoon assets config
  config.assets.precompile += [
    "teaspoon.css",
    "teaspoon-mocha.js",
    "mocha/1.17.1.js"
  ]

  config.middleware.use Rack::Attack

  config.active_storage.service = :local
end
