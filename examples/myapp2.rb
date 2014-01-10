include_recipe "database::mysql"
include_recipe "git::default"

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
    :password => "password",
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
