def ensure_log_goes_to_stdout
  old_logger = Webpacker.logger
  Webpacker.logger = ActiveSupport::Logger.new(STDOUT)
  yield
ensure
  Webpacker.logger = old_logger
end

namespace :complaints do
  namespace :webpacker do
    desc "Install deps with yarn"
    task :yarn_install do
      Webpacker.logger.info "yarn install"
      Dir.chdir(File.join(__dir__, "../..")) do
        system "yarn install --no-progress --production"
      end
    end

    desc "Install root deps with yarn"
    task :root_yarn_install do
      Webpacker.logger.info "root yarn install"
      system "yarn install --no-progress --production"
    end

    desc "Compile JavaScript packs using webpack for production with digests"
    task compile: [:root_yarn_install, :yarn_install, :environment] do
      Webpacker.with_node_env("production") do
        ensure_log_goes_to_stdout do
          if Complaints.webpacker.commands.compile
            Webpacker.logger.info "successful webpacker compilation"
            # Successful compilation!
          else
            Webpacker.logger.info "failed webpacker compilation"
            # Failed compilation
            exit!
          end
        end
      end
    end


    namespace :local do
      desc "Compile JavaScript packs locally into locally_precompiled_packs directory"
      task compile: [:yarn_install, :environment] do
        Webpacker.with_node_env("local_precompile") do
          ensure_log_goes_to_stdout do
            if Complaints.webpacker.commands.compile
              config = Complaints.webpacker.config
              public_output_path=config.public_output_path
              exec "mv #{public_output_path} #{File.join(config.public_path,"locally_precompiled_packs")}"
              # Successful compilation!
            else
              # Failed compilation
              exit!
            end
          end
        end
      end #/task
    end
  end
end

def yarn_install_available?
  rails_major = Rails::VERSION::MAJOR
  rails_minor = Rails::VERSION::MINOR

  rails_major > 5 || (rails_major == 5 && rails_minor >= 1)
end

def enhance_assets_precompile
  # yarn:install was added in Rails 5.1
  deps = yarn_install_available? ? [] : ["complaints:webpacker:yarn_install"]
  Rake::Task["assets:precompile"].enhance(deps) do
    Webpacker.logger.info "invoke complaints:webpacker:compile"
    Rake::Task["complaints:webpacker:compile"].invoke
  end
end

# Compile packs after we've compiled all other assets during precompilation
skip_webpacker_precompile = %w(no false n f).include?(ENV["WEBPACKER_PRECOMPILE"])

#unless skip_webpacker_precompile
  if Rake::Task.task_defined?("assets:precompile")
    Webpacker.logger.info "invoke enhance_assets_precompile"
    enhance_assets_precompile
  else
    Webpacker.logger.info "invoke assets precompile with webpacker dependency"
    Rake::Task.define_task("assets:precompile" => "complaints:webpacker:compile")
  end
#end
