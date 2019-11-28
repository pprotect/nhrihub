namespace :db do
  desc "creates a copy of the remote db and load it into the local development db"
  task :sync do
    on roles(:all) do
      execute "cd #{current_path} && RAILS_ENV=production rake db:snapshot "
      ssh_host = host.hostname
      backup_files = current_path.join('tmp','backups*')
      run_locally do
        system "rsync -Pav -e ssh  #{ssh_host}:'#{backup_files}' db/backups"
        system "rake db:restore"
      end
    end
  end
end
