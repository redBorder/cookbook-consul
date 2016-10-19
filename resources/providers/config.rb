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

    #Check if there are consul servers
    there_are_servers = system('serf members -tag consul=ready | grep consul=ready &> /dev/null')

    # Determine if current node must be in bootstrap mode. If there are any consul configured, bootstrap false.
    # If not, bootstrap must be true.
    is_server ? bootstrap = !there_are_servers : bootstrap = false

    # Update DNS provided by dhclient
    current_dns = `cat /etc/redborder/original_resolv.conf /etc/resolv.conf 2>/dev/null | grep nameserver | head -n1 | awk {'print $2'}`.chomp
    node.set["consul"]["dns_local_ip"] = current_dns
    dns_local_ip = node["consul"]["dns_local_ip"]

    # Calculate consul server list using serf
    server_list = `serf members -tag consul=ready -format=json | jq [.members[].addr] 2>/dev/null | sed 's/:[[:digit:]]\\+//' | tr -d '\n'`

    if is_server or (!is_server and there_are_servers)

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

      # Check if chef server is registered to delete chef in /etc/hosts
      consul_response = `curl #{node["ipaddress"]}:8500/v1/catalog/services 2>/dev/null | jq .erchef`
      (consul_response == "null\n" or consul_response == "") ? chef_registered = false : chef_registered = true
      if chef_registered
        execute 'Removing chef service from /etc/hosts' do
          command "sed -i 's/.*erchef.*//g' /etc/hosts"
        end
      end

      if is_server
        execute 'Set consul ready' do
          command "serf tags -set consul=ready"
        end
      end

      node.set["consul"]["configured"] = true
    else
        Chef::Log.info("Skipping consul configuration, there aren't any consul server yet")
    end

    node.set["consul"]["is_server"] = is_server

    Chef::Log.info("Consul cookbook has been processed")
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

    Chef::Log.info("Consul cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end
