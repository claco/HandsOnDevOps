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

directory "/var/www/myapp/shared/config" do
  owner "build"
  group "build"
  mode "0755"
  recursive true
end

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
  password      "password"
  database_name "myapp"
  host          "localhost"
  privileges    [:all]
  action        [:create, :grant]
end

template "/var/www/myapp/shared/config/database.yml" do
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
    :password => "password",
    :socket => "/var/run/mysqld/mysqld.sock"
  )
end

template "/var/www/myapp/shared/config/unicorn.rb" do
  source "unicorn.rb.erb"
  owner "build"
  group "build"
  mode "0440"
  variables :listen => "8000"
end
