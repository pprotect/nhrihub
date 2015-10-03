require File.expand_path('../boot', __FILE__)
require File.expand_path('../../lib/constants', __FILE__)

# Pick the frameworks you want:
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

require File.expand_path('../../lib/rails_class_extensions', __FILE__)

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Apf
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    config.i18n.default_locale = :en


    config.action_mailer.default_url_options = {:host => SITE_URL}
    #
  # rails 4.2 deprecation warning:
  # DEPRECATION WARNING: Currently, Active Record suppresses errors raised within 
  # `after_rollback`/`after_commit` callbacks and only print them to the logs.
  # In the next version, these errors will no longer be suppressed.
  # Instead, the errors will propagate normally just like in other Active Record callbacks.
  # You can opt into the new behavior and remove this warning by setting:
    config.active_record.raise_in_transactional_callbacks = true
  end
end
