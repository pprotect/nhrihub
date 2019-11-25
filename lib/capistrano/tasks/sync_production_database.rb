namespace :db do
  desc "creates a copy of the remote db and load it into the local development db"
  task :sync do
    on roles(:all) do
      execute "cd #{current_path} && RAILS_ENV=production rake db:snapshot "
      run_locally "rsync --remove-source-files --rsh=ssh #{user}@#{domain}:'#{current_path}/tmp/backups*' db/backups"
      run_locally "rake db:restore"
    end
  end
end
