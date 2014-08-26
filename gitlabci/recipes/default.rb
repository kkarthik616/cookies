#
# Cookbook Name:: gitlab
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
execute "apt-get-update" do
command "apt-get update"
end

%w{wget curl gcc checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev openssh-server git-core libyaml-dev postfix libpq-dev libicu-dev build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev libmysqlclient-dev }.each do |pkg|
  package pkg do
    action :install
  end
end

package "redis-server" do
action :install
end

package "mysql-server" do
action :install
end

package "mysql-client" do
action :install
end


bash 'build ruby from source' do 
  code <<-EOF
        cd /tmp/sql
           wget http://cache.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p481.tar.gz
           tar -xvzf ruby-2.0.0-p481.tar.gz
        cd ruby-2.0.0-p481/
           ./configure --prefix=/usr/local
        make
sudo make install
  EOF
only_if do ! File.exists?("/usr/local/bin/ruby") end
end

execute "gem install bundler" do
command "gem install bundler --no-ri --no-rdoc"
end

group "gitlab_ci" do
  action :create
end

user "gitlab_ci" do
  gid "gitlab_ci" 
  shell "/bin/bash"
  home "/home/gitlab_ci" 
  system true
  action :create
end

cookbook_file "/tmp/test.sql" do
source "test.sql"
end

execute "create-db" do
action :run
command "mysql -u root < /tmp/test.sql"
end

git "/home/gitlab_ci/" do
   repository "https://gitlab.com/gitlab-org/gitlab-ci.git"
   revision "5-0-stable" 
   action :sync
end

git "/home/gitlab_ci/gitlab-ci" do
   repository "https://gitlab.com/gitlab-org/gitlab-ci.git"
   revision "5-0-stable"
   action :checkout
end

execute "production-settings" do
command "cp /home/gitlab_ci/gitlab-ci/config/application.yml.example /home/gitlab_ci/gitlab-ci/config/application.yml"
end

execute "web-server-settings" do
command "sudo cp /home/gitlab_ci/gitlab-ci/config/unicorn.rb.example /home/gitlab_ci/gitlab-ci/config/unicorn.rb " 
end

execute "add-socket-directories" do
cwd "/home/gitlab_ci/gitlab-ci/"
command "sudo mkdir -p tmp/sockets/ ; sudo chmod -R 777 tmp/sockets/"
not_if { File.exist?("/home/gitlab_ci/gitlab-ci/tmp/sockets") }
end

execute "add-pid-directories" do
cwd "/home/gitlab_ci/gitlab-ci/tmp/"
command "sudo mkdir pids/ ; sudo chmod -R 777 pids/"
not_if { File.exist?("/home/gitlab_ci/gitlab-ci/tmp/pids") }
end

execute "install-gems" do
cwd "/home/gitlab_ci/gitlab-ci/"
command "bundle install --without development test postgres --deployment"
end

#execute "setup-db" do
#command " cp /home/gitlab_ci/gitlab-ci/config/database.yml.mysql /home/gitlab_ci/gitlab-ci/config/database.yml"
#not_if { File.exist?("/home/gitlab_ci/gitlab-ci/config/database.yml") }
#end


execute "install-init-script" do
command "sudo cp /home/gitlab_ci/gitlab-ci/lib/support/init.d/gitlab_ci /etc/init.d/gitlab_ci"
end

execute "change-permissions" do
command "sudo chown gitlab_ci.gitlab_ci /home/gitlab_ci -R"
end

directory "/home/gitlab_ci/gitlab-ci/log/" do
  owner "gitlab_ci"
  group "gitlab_ci"
  mode 00777
  action :create
end

directory "/home/gitlab_ci/gitlab-ci/tmp/cache" do
  owner "gitlab_ci"
  group "gitlab_ci"
  mode 00777
  action :create
end

execute "change-permission" do
command "chmod 777 /home/gitlab_ci/gitlab-ci/tmp/"
end

service "gitlab_ci" do
action [:enable , :start]
end

#execute "service-start" do
#action :run
#cwd "/etc/init.d"
#command "service gitlab_ci start"
#end

package "nginx" do
action :install
end

execute "site-configuration" do
command "cp /home/gitlab_ci/gitlab-ci/lib/support/nginx/gitlab_ci /etc/nginx/sites-available/gitlab_ci"
not_if { File.exist?("/etc/nginx/sites-available/gitlab_ci") }
end

execute "link" do
command "ln -s /etc/nginx/sites-available/gitlab_ci /etc/nginx/sites-enabled/gitlab_ci"
not_if { File.exist?("/etc/nginx/sites-enabled/gitlab_ci") }
end

template "/home/gitlab_ci/config/database.yml" do
source "database.yml.mysql"
end

template "/etc/nginx/sites-enabled/gitlab_ci" do
source "gitlab_ci.erb"
end

gem_package "rake" do
action :install
not_if { File.exist?("/usr/local/bin/rake") }
end

#execute "setup_db" do
#cwd "/home/gitlab_ci"
#command "bundle exec rake setup RAILS_ENV=production"
#command "RAILS_ENV=production bundle exec rake db:migrate"
#end

#execute "setup_db" do
#cwd "/home/gitlab_ci"
#command "bundle exec whenever -w RAILS_ENV=production"
#end

service "nginx" do
action [:enable, :start]
end
