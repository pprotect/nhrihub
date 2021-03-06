def ensure_log_goes_to_stdout
  old_logger = Webpacker.logger
  Webpacker.logger = ActiveSupport::Logger.new(STDOUT)
  yield
ensure
  Webpacker.logger = old_logger
end

namespace :projects do
  namespace :webpacker do
    desc "Install deps with yarn"
    task :yarn_install do
      Dir.chdir(File.join(__dir__, "../..")) do
        system "yarn install --no-progress --production"
      end
    end

    desc "Install root deps with yarn"
    task :root_yarn_install do
      system "yarn install --no-progress --production"
    end

    desc "Compile JavaScript packs using webpack for production with digests"
    task compile: [:root_yarn_install, :yarn_install, :environment] do
      Webpacker.with_node_env("production") do
        ensure_log_goes_to_stdout do
          if Projects.webpacker.commands.compile
            Webpacker.logger.info "successful projects webpacker compilation"
            # Successful compilation!
          else
            Webpacker.logger.info "failed projects webpacker compilation"
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
            if Projects.webpacker.commands.compile
              config = Projects.webpacker.config
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

def enhanced_projects_assets_precompile
  # yarn:install was added in Rails 5.1
  deps = yarn_install_available? ? [] : ["projects:webpacker:yarn_install"]
  Rake::Task["assets:precompile"].enhance(deps) do
    Rake::Task["projects:webpacker:compile"].invoke
  end
end

# Compile packs after we've compiled all other assets during precompilation
skip_webpacker_precompile = %w(no false n f).include?(ENV["WEBPACKER_PRECOMPILE"])

unless skip_webpacker_precompile
  if Rake::Task.task_defined?("assets:precompile")
    enhanced_projects_assets_precompile
  else
    Rake::Task.define_task("assets:precompile" => "projects:webpacker:compile")
  end
end
