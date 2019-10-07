module Projects
  class Engine < ::Rails::Engine
    initializer "projects.webpacker.proxy" do |app|
        insert_middleware = begin
                            Projects.webpacker.config.dev_server.present?
                          rescue
                            nil
                          end
        next unless insert_middleware

        app.middleware.insert_before(
          0, Webpacker::DevServerProxy, # "Webpacker::DevServerProxy" if Rails version < 5
          ssl_verify_none: true,
          webpacker: Projects.webpacker
        )

      end # /initializer

      config.app_middleware.use(
        Rack::Static,
        urls: ["/projects_packs"], root: "vendor/gems/projects/public"
      )
  end
end
