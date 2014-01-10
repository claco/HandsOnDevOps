require "bundler/capistrano"
require "capistrano-unicorn"

set :application, "myapp"
set :deploy_to,   "/var/www/#{application}"
set :user, "build"
set :use_sudo, false
set :repository, "."
set :scm, :none
set :deploy_via, :copy
set :unicorn_bin, :unicorn_rails
set :rails_env, :production
set :unicorn_rack_env, :production

role :web, "192.168.33.20"
role :app, "192.168.33.20"
role :db,  "192.168.33.20", :primary => true

after "deploy:update", "db:copy_config"
after "deploy:update", "unicorn:copy_config"

namespace :db do
  desc 'Copies shared database.yml'
  task :copy_config do
    run "cd #{current_path} && ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
end

namespace :unicorn do
  desc 'Copies shared unicorn.rb'
  task :copy_config do
    run "cd #{current_path} && ln -nfs #{shared_path}/config/unicorn.rb #{release_path}/config/unicorn.rb"
  end
end
