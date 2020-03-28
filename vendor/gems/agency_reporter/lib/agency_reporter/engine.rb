module AgencyReporter
  class Engine < ::Rails::Engine
    config.mount_at = '/'

    # include the locales translations from the module
    config.i18n.load_path += Dir.glob(config.root.join('config','locales','**','*.{rb,yml}'))

    # append module migrations to the main app
    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
