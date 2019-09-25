require "rspec/core/rake_task"

task :default do
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = "{,vendor/gems/*/}spec/{features,models,mailers}/**/*_spec.rb"
  end
  Rake::Task["spec"].execute
end

# because rails must be reloaded between specs
# as the specs depend on rails configuration
desc "run request specs"
task :requests do
  puts `rspec spec/requests/browser_check_spec.rb`
  puts `rspec spec/requests/browser_check_fr_spec.rb`
  puts `rspec spec/requests/error_pages_spec.rb`
end

desc "run all model specs"
task :models => :spec do
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = "{,vendor/gems/*/}spec/models/**/*_spec.rb"
  end
  Rake::Task["spec"].execute
end

desc "javascript test shortcut"
task :js do
  `rm -rf tmp/cache/assets/sprockets/v3.0/`
  puts `RAILS_ENV=jstest rake teaspoon suite=default`
end
