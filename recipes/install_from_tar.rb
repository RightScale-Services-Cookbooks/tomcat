#
# Cookbook Name:: tomcat
# Recipe:: default
#
# Copyright 2010, Opscode, Inc.
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


package "redhat-lsb-core" do
  only_if { node['platform_family'] == 'rhel' }
end

#override some variables for tar file
node.override['tomcat']['base']= node['tomcat']['home']
#node.override['tomcat']['config_dir']= "#{node['tomcat']['home']}/conf"

# download the the file
filename = "/tmp/tomcat#{node["tomcat"]["base_version"]}"
remote_file filename do
  source "http://archive.apache.org/dist/tomcat/tomcat-#{node["tomcat"]["base_version"]}/v#{node["tomcat"]["tar_version"]}/bin/apache-tomcat-#{node["tomcat"]["tar_version"]}.tar.gz"
end

# create install directories
directory node["tomcat"]["home"] do
  action :create
end

directory "#{node["tomcat"]["home"]}/conf/Catalina/localhost" do
  recursive true
  action :create
end

# create user and group for init.d script to use
user node["tomcat"]["user"] do
  system true
  action :create
end

group node["tomcat"]["group"] do
  members  node["tomcat"]["user"]
  system true
  action :create
end

template "/etc/init.d/tomcat#{node["tomcat"]["base_version"]}" do
  source "init.conf.erb"
  mode 0755
  variables ({
      :user => node["tomcat"]["user"],
      :group => node["tomcat"]["group"],
      :name => "tomcat#{node["tomcat"]["base_version"]}"
  }
  )
end

bash "extracting #{filename}" do
  cwd 
  code <<-EOF
    tar -xzvf #{filename} -C /usr/share/tomcat#{node["tomcat"]["base_version"]} --strip-components=1
    chown -R #{node["tomcat"]["user"]}:#{node["tomcat"]["group"]} /usr/share/tomcat#{node["tomcat"]["base_version"]}
  EOF
  
end

link node["tomcat"]["log_dir"] do
  to "#{node["tomcat"]["home"]}/logs"
  #notifies :restart, resources(:service => "tomcat#{node['tomcat']['base_version']}")
end
  
link node["tomcat"]["config_dir"] do
  to "#{node["tomcat"]["home"]}/conf"
end

file "/tmp/tomcat#{node["tomcat"]["base_version"]}" do
  action :delete
end