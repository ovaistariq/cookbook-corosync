#
# Cookbook Name:: corosync
# Recipe:: authkey
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

require 'base64'

if Chef::Config[:solo]
  Chef::Application.fatal! "This recipe uses search. Chef Solo does not support search."
  return
end

cluster_name = node[:corosync][:cluster_name]
unless cluster_name and ! cluster_name.empty?
  Chef::Application.fatal! "Couldn't figure out corosync cluster name"
  return
end

# Find pre-existing authkey on other node(s)
query  = "chef_environment:#{node.chef_environment}"
query += " AND corosync_cluster_name:#{cluster_name}"
query += " AND corosync:authkey"

authkey_node = nil
log("search query: #{query}")
authkey_nodes = search(:node, query)
log("nodes with authkey: #{authkey_nodes}")

if authkey_nodes.length == 0
  include_recipe "corosync::authkey_generator"
elsif authkey_nodes.length > 0
  authkey_node = authkey_nodes[0]

  if authkey_node[:corosync][:authkey] == nil
    authkey_node = nil
    include_recipe "corosync::authkey_generator"
  end
end

if authkey_node != nil
  log("Using corosync authkey from node: #{authkey_node.name}")
  authkey = authkey_node[:corosync][:authkey]

  node.set[:corosync][:authkey] = authkey
  node.save
  include_recipe "corosync::authkey_writer"
end
