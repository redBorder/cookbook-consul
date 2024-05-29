# Cookbook:: consul
# Recipe:: default
# Copyright:: 2024, redborder
# License:: Affero General Public License, Version 3

consul_config 'Configure Consul' do
  confdir node['consul']['confdir']
  datadir node['consul']['datadir']
  ipaddress node['ipaddress']
  cdomain node['redborder']['cdomain']
  dns_local_ip node['consul']['dns_local_ip']
  action :add
end

# consul_config 'Configure Consul' do
#   confdir node['consul']['confdir']
#   datadir node['consul']['datadir']
#   cdomain node['redborder']['cdomain']
#   dns_local_ip node['consul']['dns_local_ip']
#   action :remove
# end
