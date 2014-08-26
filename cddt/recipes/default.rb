# Cookbook Name:: cddt
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute

execute "apt-get update" do
command "apt-get update"
end

%w{git-core git-daemon-run openjdk-7-jdk libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev build-essential jenkins subversion maven expect}.each do |pkg|
  package pkg do
    action :install
  end
end

ant_pkgs = ["ant 1.8","ant-contrib","ivy"].each do |pkg|
package pkg do
action :install
end
end

#package "jboss" do
#action :install
#end

unzip "http://download.jboss.org/jbossas/7.0/jboss-as-7.0.0.Final/jboss-as-web-7.0.0.Final.zip" do
action :install
end


template "/etc/apt/sources.list" do
source "sources.list"
mode 00777
end

package "sonar" do
options "--force-yes"
action :install
end

package "nginx" do
action :install
end

file "/etc/nginx/sites-available/default" do
action :delete
end

file "/etc/nginx/sites-enabled/default" do
action :delete
end

cookbook_file "/etc/nginx/sites-available/jenkins" do
source "jenkins"
action :create_if_missing
end

execute "create_link" do
command "sudo ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/"
not_if { ::File.exists?("/etc/nginx/sites-enabled/jenkins")}
end

service "nginx" do
action [:enable,:start]
end

group "appserver" do
action :create
end 

user "appserver" do
gid "appserver"
action :create
end

execute "change_ownership" do
command "chown -R appserver.appserver /usr/local/share/jboss"
end

bash "modify_root_password" do
    code <<-EOF
    su appserver;cd /usr/local/share/jboss/bin;./add-user.sh
    /usr/bin/expect -c 'spawn passwd
    expect "\(a\):"
    send "a"
    expect "Username :"
    send "app1"
    expect "Password :"
    send "passowrd"
    expect "Re-enter Password :"
    send "password"
    expect eof'
    EOF
end

execute "startJBossAS" do
command "./standalone.sh -Djboss.bind.address=node['ipaddress'] -Djboss.bind.address.management=yourserverip&"
end

