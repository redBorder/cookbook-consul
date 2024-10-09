# Cookbook:: consul
# Provider:: config

action :install do
  begin
    user = new_resource.user
    group = new_resource.group
    confdir = new_resource.confdir
    datadir = new_resource.datadir

    dnf_package 'consul' do
      action :upgrade
      flush_cache [:before]
    end

    directory confdir do
      owner user
      group group
      mode '0770'
      action :create
    end

    directory datadir do
      owner user
      group group
      mode '0770'
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
    log_level = new_resource.log_level

    consul_config 'Install consul package' do
      confdir node['consul']['confdir']
      datadir node['consul']['datadir']
      action :install
    end

    # Check if there are consul servers
    there_are_servers = system('serf members -tag consul=ready | grep consul=ready &> /dev/null')

    # Determine if current node must be in bootstrap mode. If there are any consul configured, bootstrap false.
    # If not, bootstrap must be true.
    bootstrap = is_server ? !there_are_servers : false

    # Update DNS provided by dhclient
    # Check if DNS was configured in the wizard..
    RBETC = ENV['RBETC'].nil? ? '/etc/redborder' : ENV['RBETC']
    init_conf = YAML.load_file("#{RBETC}/rb_init_conf.yml")
    network = init_conf['network']
    current_dns = network['dns'].nil? ? `cat /etc/redborder/original_resolv.conf /etc/resolv.conf 2>/dev/null | grep nameserver | awk {'print $2'}`.split('\n') : network['dns']
    node.normal['consul']['dns_local_ip'] = current_dns
    dns_local_ip = node['consul']['dns_local_ip']

    # Calculate consul server list using serf
    server_list = `serf members -tag consul=ready -format=json | jq [.members[].addr] 2>/dev/null | sed 's/:[[:digit:]]\\+//' | tr -d '\n'`

    if is_server || (!is_server && there_are_servers)

      template "#{confdir}/consul.json" do
        source 'consul.json.erb'
        cookbook 'consul'
        owner user
        group group
        mode '0644'
        retries 2
        variables(cdomain: cdomain, datadir: datadir, hostname: node['hostname'], is_server: is_server, \
          ipaddress: ipaddress, bootstrap: bootstrap, server_list: server_list, dns_local_ip: dns_local_ip, log_level: log_level)
        notifies :reload, 'service[consul]'
      end

      template '/etc/resolv.conf' do
        source 'resolv.conf.erb'
        cookbook 'consul'
        owner user
        group group
        mode '0644'
        retries 2
        variables(cdomain: cdomain, dns_ip: ipaddress)
      end

      template '/etc/sysconfig/network' do
        source 'network.erb'
        cookbook 'consul'
        owner user
        group group
        mode '0644'
        retries 2
        variables(cdomain: cdomain, dns_ip: ipaddress)
      end

      service 'consul' do
        service_name 'consul'
        ignore_failure true
        supports status: true, reload: true, restart: true, enable: true
        action [:enable, :start]
      end

      # Check if chef server is registered to delete chef in /etc/hosts
      consul_response = `curl #{node['ipaddress']}:8500/v1/catalog/services 2>/dev/null | jq .erchef`
      chef_registered = (consul_response == 'null\n' || consul_response == '') ? false : true
      if chef_registered
        execute 'Removing chef service from /etc/hosts' do
          command "sed -i 's/.*erchef.*//g' /etc/hosts"
        end
      end

      # Check if postgresql is registered in Consul
      consul_response = `curl #{node['ipaddress']}:8500/v1/catalog/services 2>/dev/null | jq .postgresql`
      postgresql_registered = (consul_response == 'null\n' || consul_response == '') ? false : true

      # Check if the virtual IP field exists in the data bag
      data_bag_response = `knife data bag show rBglobal ipvirtual-internal-postgresql 2>/dev/null`
      virtual_ip_present = (data_bag_response.include?('ip:')) ? true : false

      # Get the list of alive server members from Serf
      alive_server_members = `serf members -format=json -status=alive`
      postgresql_nodes = JSON.parse(alive_server_members) unless alive_server_members.strip.empty?

      # If all conditions are met /etc/hosts will be removed
      if postgresql_registered && !virtual_ip_present && postgresql_nodes['members'].size == 1
        execute 'Removing postgresql service from /etc/hosts' do
          command "sed -i 's/.*postgresql.*//g' /etc/hosts"
        end
      end

      if is_server
        execute 'Set consul ready' do
          command 'serf tags -set consul=ready'
        end
      end

      node.normal['consul']['configured'] = true
    else
      Chef::Log.info('Skipping consul configuration, there arent any consul server yet')
    end

    node.normal['consul']['is_server'] = is_server

    Chef::Log.info('Consul cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    user = new_resource.user
    group = new_resource.group
    # confdir = new_resource.confdir
    # datadir = new_resource.datadir
    cdomain = new_resource.cdomain
    dns_local_ip = new_resource.dns_local_ip

    service 'consul' do
      service_name 'consul'
      supports status: true, stop: true
      action :stop
    end

    # dir_list = [datadir, confdir]

    # dir_list.each do |dir|
    #   directory dir do
    #     recursive true
    #     action :delete
    #   end
    # end

    template '/etc/resolv.conf' do
      source 'resolv.conf.erb'
      cookbook 'consul'
      owner user
      group group
      mode '0644'
      retries 2
      variables(cdomain: cdomain, dns_ip: dns_local_ip)
    end

    # removing package
    # dnf_package 'consul' do
    #   action :remove
    # end

    node.normal['consul']['configured'] = false

    Chef::Log.info('Consul cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end
