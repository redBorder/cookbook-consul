# Cookbook:: consul
# Provider:: config

include Consul::Helper

action :install do
  begin
    user = new_resource.user
    group = new_resource.group
    confdir = new_resource.confdir
    datadir = new_resource.datadir

    dnf_package 'consul' do
      action :upgrade
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

    # Update DNS provided by dhclient
    # Check if DNS was configured in the wizard..
    RBETC = ENV['RBETC'].nil? ? '/etc/redborder' : ENV['RBETC']
    init_conf = YAML.load_file("#{RBETC}/rb_init_conf.yml")
    network = init_conf['network']
    current_dns = network['dns'].nil? ? `cat /etc/redborder/original_resolv.conf /etc/resolv.conf 2>/dev/null | grep nameserver | awk {'print $2'}`.split('\n') : network['dns']
    node.normal['consul']['dns_local_ip'] = current_dns
    dns_local_ip = node['consul']['dns_local_ip']

    if is_server
      execute 'Set consul ready' do
        command 'serf tags -set consul=ready'
      end
    else
      execute 'Unset consul ready' do
        command 'serf tags -delete consul'
      end
    end

    # Calculate consul server list using serf
    server_list = get_server_list
    bootstrap_expect = get_server_count

    if ::Dir.exist?('/tmp/consul')
      migrate_consul_config("#{confdir}/consul.json", '/tmp/consul', datadir)
    end

    template "#{confdir}/consul.json" do
      source 'consul.json.erb'
      cookbook 'consul'
      owner user
      group group
      mode '0644'
      retries 2
      variables(cdomain: cdomain, datadir: datadir, hostname: node['hostname'], is_server: is_server, \
        ipaddress: ipaddress, server_list: server_list, dns_local_ip: dns_local_ip, log_level: log_level, bootstrap_expect: bootstrap_expect)
      notifies :restart, 'service[consul]'
    end

    template '/etc/resolv.conf' do
      source 'resolv.conf.erb'
      cookbook 'consul'
      owner user
      group group
      mode '0644'
      retries 2
      variables(cdomain: cdomain, dns_ip: ipaddress, is_server: is_server, server_list: server_list)
    end

    template '/etc/sysconfig/network' do
      source 'network.erb'
      cookbook 'consul'
      owner user
      group group
      mode '0644'
      retries 2
      variables(cdomain: cdomain, dns_ip: ipaddress, is_server: is_server, server_list: server_list)
    end

    service 'consul' do
      service_name 'consul'
      ignore_failure true
      supports status: true, reload: true, restart: true, enable: true
      action [:enable, :start]
    end

    # Check if any serf member has the leader=inprogress tag
    serf_members_output = `serf members`
    leader_inprogress = serf_members_output.include?('leader=inprogress')

    # Check if chef server is registered to delete chef in /etc/hosts
    consul_response = `curl #{node['ipaddress']}:8500/v1/catalog/services 2>/dev/null | jq .erchef`
    chef_registered = (consul_response == 'null\n' || consul_response == '') ? false : true
    if chef_registered && !leader_inprogress
      execute 'Removing chef service from /etc/hosts' do
        command "sed -i 's/.*erchef.*//g' /etc/hosts"
      end
    end

    node.normal['consul']['is_server'] = is_server
    node.normal['consul']['configured'] = true

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
