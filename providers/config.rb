# Cookbook Name:: consul
#
# Provider:: config
#

action :add do
  begin
    logdir = new_resource.logdir
    user = new_resource.user
    group = new_resource.group

    yum_package "consul" do
      action :upgrade
      flush_cache [:before]
    end

    group group do
      action  :create
    end

    user user do
      group group
      action :create
    end

    directory logdir do
      owner user
      group group
      mode 0770
      action :create
    end

    service "consul" do
      service_name "consul"
      ignore_failure true
      supports :status => true, :reload => true, :restart => true, :enable => true
      action [:enable,:start]
    end

    Chef::Log.info("Consul has been configured correctly.")
  rescue => e
    Chef::Log.error(e.message)
  end
end


action :remove do
  begin
    user = new_resource.user
    group = new_resource.group
    logdir = new_resource.logdir
    confdir = new_resource.confdir


    service "consul" do
      service_name "consul"
      supports :status => true, :stop => true
      action :stop
    end

    dir_list = [
      logdir,
      confdir
    ]

    dir_list.each do |dir|
      directory dir do
        recursive true
        action :delete
      end
    end

    # removing package
    yum_package 'consul' do
      action :remove
    end

    Chef::Log.info("Consul has been removed correctly.")
  rescue => e
    Chef::Log.error(e.message)
  end
end
