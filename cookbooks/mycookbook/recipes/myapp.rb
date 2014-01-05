#
# Cookbook Name:: mycookbook
# Recipe:: myapp
#
# Copyright 2014, Christopher H. Laco
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "database::mysql"
include_recipe "git::default"

mysql_secret = Chef::EncryptedDataBagItem.load_secret("/vagrant/.chef/encrypted_data_bag_secret")
mysql_creds = Chef::EncryptedDataBagItem.load("passwords", "mysql", mysql_secret)
myapp_password = mysql_creds["myapp"]

mysql_connection_info = {
  :username => "root",
  :password => node["mysql"]["server_root_password"],
  :socket   => node["mysql"]["socket"]
}

mysql_database "myapp" do
  connection mysql_connection_info
  action :create
end

mysql_database_user "myapp" do
  connection    mysql_connection_info
  password      myapp_password
  database_name "myapp"
  host          "localhost"
  privileges    [:all]
  action        [:create, :grant]
end

%w{config log bundle pids system cached-copy sockets}.each do |dir|
  directory "/var/www/myapp2/shared/#{dir}" do
    owner "build"
    group "build"
    mode "0755"
    recursive true
  end
end

template "/var/www/myapp2/shared/config/database.yml" do
  source "database.yml.erb"
  owner "build"
  group "build"
  mode "0440"
  variables(
    :environment => "production",
    :adapter => "mysql2",
    :encoding => "utf8",
    :database => "myapp",
    :pool => 10,
    :username => "myapp",
    :password => myapp_password,
    :socket => "/var/run/mysqld/mysqld.sock"
  )
end

template "/var/www/myapp2/shared/config/unicorn.rb" do
  source "unicorn.rb.erb"
  owner "build"
  group "build"
  mode "0440"
  variables :listen => "9000"
end

deploy_branch "/var/www/myapp2" do
  user "build"
  group "build"
  repo "file:///vagrant/myapp.git"
  shallow_clone true
  environment "RAILS_ENV" => "production"
  branch "master"
  action :force_deploy
  migrate true
  migration_command "bundle exec rake db:migrate > log/migrate.log 2>&1"
  restart_command "bundle exec unicorn_rails -c /var/www/myapp2/current/config/unicorn.rb -E production -D"
  create_dirs_before_symlink  %w{tmp public config deploy}
  symlink_before_migrate      "config/database.yml" => "config/database.yml",
                              "config/unicorn.rb" => "config/unicorn.rb",
                              "log" => "log"

  symlinks "system"  => "public/system",
           "sockets" => "tmp/sockets",
           "pids"    => "tmp/pids"

  before_migrate do
    execute "bundle install" do
      cwd release_path
      command "bundle install --path /var/www/myapp2/shared/bundle --deployment --without development test"
    end
  end
end
