#
# Cookbook Name:: consul
# Recipe:: default
#
# Redborder, 2016
#
# AFFERO GENERAL PUBLIC LICENSE V3
#

consul_config "Consul config" do
  logdir node["consul"]["logdir"]
  confdir node["consul"]["confdir"]
  action :add
end
