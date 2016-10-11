#
# Cookbook Name:: consul
# Recipe:: default
#
# Redborder, 2016
#
# AFFERO GENERAL PUBLIC LICENSE V3
#

# For testing purposes

consul_config "Configure Consul" do
  confdir node["consul"]["confdir"]
  datadir node["consul"]["datadir"]
  ipaddress node["ipaddress"]
  cdomain node["redborder"]["cdomain"]
  dns_local_ip node["consul"]["dns_local_ip"]
  action :add
end

#consul_config "Configure Consul" do
#  confdir node["consul"]["confdir"]
#  datadir node["consul"]["datadir"]
#  cdomain node["redborder"]["cdomain"]
#  dns_local_ip node["consul"]["dns_local_ip"]
#  action :remove
#end
