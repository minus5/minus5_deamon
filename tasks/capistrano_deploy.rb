Capistrano::Configuration.instance(:must_exist).load do 

  #nakon deploya simlinkaj config fileove u /config dir
  #config fileovi se nalaze u shared/config
  after "deploy:update_code", "symlink_configs"
  task :symlink_configs do  
    run "ln -nfs #{shared_path}/config/config.yml #{release_path}/config/config.yml"
  end

  #start stop servisa
  namespace :deploy do
    desc "Restarting daemon"
    task :restart do
      run "#{current_path}/bin/#{application}.rb restart"
    end

    desc "Stopping daemon"
    task :stop do
      run "#{current_path}/bin/#{application}.rb stop"
    end
  end

  after "deploy:setup", "fix_dir_permissions"
  task :fix_dir_permissions do
    dirs = [deploy_to, releases_path, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    group = deploy_group || "admin"
    run "#{try_sudo} chgrp #{group} #{dirs.join(' ')}"
  end

  after "deploy:setup", "create_config_yml"
  task :create_config_yml do
    dirs = ["#{shared_path}/config"]
    run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
    run "#{try_sudo} chgrp #{deploy_group} #{dirs.join(' ')}"
    run "touch #{shared_path}/config/config.yml"
  end

end
