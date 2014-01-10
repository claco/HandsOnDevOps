execute "add-mysql-user" do
  command "/usr/bin/mysql -u root -D mysql -r -B -N -e \"CREATE USER 'myapp'@'localhost' IDENTIFIED BY 'password'\""
  action :run
  only_if { `/usr/bin/mysql -u root -D mysql -r -B -N -e "SELECT COUNT(*) FROM user where User='myapp' and Host='localhost'"`.to_i == 0 }
end

execute "create-mysql-database" do
  command "/usr/bin/mysql -u root -D mysql -r -B -N -e \"CREATE DATABASE myapp CHARACTER SET utf8 COLLATE utf8_unicode_ci\""
  action :run
  only_if { `/usr/bin/mysql -u root -D mysql -r -B -N -e \"SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='myapp'\"`.to_i == 0 }
end

execute "grant-myapp-privs" do
  command "/usr/bin/mysql -u root -D mysql -r -B -N -e \"GRANT ALL on myapp.* to 'myapp'@'localhost'\""
  action :run
  only_if { `/usr/bin/mysql -u root -D mysql -r -B -N -e \"SELECT COUNT(*) FROM db where User='myapp' and Host='localhost' and Db='myapp'\"`.to_i == 0 }
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

