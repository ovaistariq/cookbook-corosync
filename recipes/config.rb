#
# Cookbook Name:: corosync
# Recipe:: client
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2015, Ovais Tariq <me@ovaistariq.net>
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

# chef makes csync2 redundant
case node["platform_family"]
when 'suse'
  service "csync2" do
    action [:stop, :disable]
  end
when 'rhel'
  Chef::Log.warn("RedHat-based platforms configure corosync via cluster.conf")
end

unless %(udp udpu).include?(node[:corosync][:transport])
  raise "Invalid transport #{node[:corosync][:transport]}!"
end

if node[:corosync][:transport] == "udpu" && (node[:corosync][:members].nil? || node[:corosync][:members].empty?)
  raise "Members have to be defined when using \"udpu\" transport!"
end

template "/etc/corosync/corosync.conf" do
  source "corosync.conf.erb"
  owner "root"
  group "root"
  mode 0600
  variables(
    :cluster_name => node[:corosync][:cluster_name],
    :bind_addr    => node[:corosync][:bind_addr],
    :mcast_addr   => node[:corosync][:mcast_addr],
    :mcast_port   => node[:corosync][:mcast_port],
    :members      => node[:corosync][:members],
    :transport    => node[:corosync][:transport]
  )

  # Stop the pacemaker service if its defined as that is needed for corosync
  # service to be able to restart
  service_name = node[:pacemaker][:platform][:service_name] rescue nil
  if service_name
    notifies :stop, "service[#{service_name}]", :immediately
  end

  notifies :restart, "service[#{node['corosync']['platform']['service_name']}]", :immediately

  # Start the pacemaker service if its defined
  service_name = node[:pacemaker][:platform][:service_name] rescue nil
  if service_name
    notifies :start, "service[#{service_name}]", :immediately
  end
end
