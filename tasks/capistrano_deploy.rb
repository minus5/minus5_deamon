Capistrano::Configuration.instance(:must_exist).load do

  #start stop deamon
  namespace :deploy do
    desc "Restarting daemon"
    task :restart do
      run "#{current_path}/lib/#{application}.rb restart"
    end

    desc "Stopping daemon"
    task :stop do
      run "#{current_path}/lib/#{application}.rb stop"
    end
  end

  after "deploy:setup", "fix_dir_permissions"
  desc "change group to deploy_group on dirs created during deploy:setup"
  task :fix_dir_permissions do
    dirs = [deploy_to, releases_path, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    group = deploy_group || "admin"
    run "#{try_sudo} chgrp #{group} #{dirs.join(' ')}"
  end

  #shared files handling (next three tasks)
  #shared files are symlinked from shared to the same location in release_path for each deploy
  #initiali empty files are created during deploy:setup
  #if file exists in relase_path it is deleted and then replaced with symlink to shared
  before "deploy:setup", "add_shard_files_to_shared_children"
  task :add_shard_files_to_shared_children do
    next unless exists?(:shared_files)
    shared_files.each do |file|
      shared_children << File.dirname(file)
    end
  end

  after "deploy:setup", "create_shared_files"
  task :create_shared_files do
    next unless exists?(:shared_files)
    shared_files.each  do |file|
      run "touch #{shared_path}/#{file}"
    end
  end

  after "deploy:update_code", "symlink_shared_files"
  task :symlink_shared_files do
    next unless exists?(:shared_files)
    shared_files.each do |file|
      run "rm -f #{release_path}/#{file}"
      run "ln -nfs #{shared_path}/#{file} #{release_path}/#{file}"
    end
  end

end





