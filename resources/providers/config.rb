# Cookbook Name:: consul
#
# Provider:: config
#

action :install do
  begin
    user = new_resource.user
    group = new_resource.group
    confdir = new_resource.confdir
    datadir = new_resource.datadir

    yum_package "consul" do
      action :upgrade
      flush_cache [:before]
    end

    directory confdir do
      owner user
      group group
      mode 0770
      action :create
    end

    directory datadir do
      owner user
      group group
      mode 0770
      action :create
    end

    Chef::Log.info("Consul has been installed correctly.")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :add do
  begin
    confdir = new_resource.confdir
    datadir = new_resource.datadir
    ipaddress = new_resource.ipaddress
    cdomain = new_resource.cdomain
    dns_local_ip = new_resource.dns_local_ip
    is_server = new_resource.is_server

    consul_config "Install consul package" do
      confdir node["consul"]["confdir"]
      datadir node["consul"]["datadir"]
      action :install
    end

    # Determine if current node is leader
    is_server ? bootstrap = system('serf members -tag leader="ready|inprogress" | grep $(hostname -s) &> /dev/null') : bootstrap = false

    # Check local DNS address
    current_dns = `cat /etc/resolv.conf | grep nameserver | head -n1 | awk {'print $2'}`.chomp

    if current_dns != ipaddress
      node.set["consul"]["dns_local_ip"] = current_dns
      dns_local_ip = node["consul"]["dns_local_ip"]
    end

    server_list = `serf members -tag bootstrap=ready -format=json | jq [.members[].addr] | sed 's/:[[:digit:]]\\+//' | tr -d '\n'`

    template "#{confdir}/consul.json" do
      source "consul.json.erb"
      cookbook "consul"
      owner user
      group group
      mode 0644
      retries 2
      variables(:cdomain => cdomain, :datadir => datadir, :hostname => node["hostname"], :is_server => is_server, \
        :ipaddress => ipaddress, :bootstrap => bootstrap, :server_list => server_list, :dns_local_ip => dns_local_ip)
      notifies :reload, "service[consul]"
    end

    template "/etc/resolv.conf" do
      source "resolv.conf.erb"
      cookbook "consul"
      owner user
      group group
      mode 0644
      retries 2
      variables(:cdomain => cdomain, :dns_ip => ipaddress)
    end

    service "consul" do
      service_name "consul"
      ignore_failure true
      supports :status => true, :reload => true, :restart => true, :enable => true
      action [:enable,:start]
    end

    node.set["consul"]["is_server"] = is_server
    node.set["consul"]["configured"] = true

    Chef::Log.info("Consul has been configured correctly.")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    user = new_resource.user
    group = new_resource.group
    confdir = new_resource.confdir
    datadir = new_resource.datadir
    cdomain = new_resource.cdomain
    dns_local_ip = new_resource.dns_local_ip

    service "consul" do
      service_name "consul"
      supports :status => true, :stop => true
      action :stop
    end

    dir_list = [
      datadir,
      confdir
    ]

    dir_list.each do |dir|
      directory dir do
        recursive true
        action :delete
      end
    end

    template "/etc/resolv.conf" do
      source "resolv.conf.erb"
      cookbook "consul"
      owner user
      group group
      mode 0644
      retries 2
      variables(:cdomain => cdomain, :dns_ip => dns_local_ip)
    end

    # removing package
    yum_package 'consul' do
      action :remove
    end

    node.set["consul"]["configured"] = false

    Chef::Log.info("Consul has been removed correctly.")
  rescue => e
    Chef::Log.error(e.message)
  end
end
