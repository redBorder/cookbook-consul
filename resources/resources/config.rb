# Cookbook Name:: Consul
#
# Resource:: config
#

actions :add, :remove, :install
default_action :add

attribute :user, :kind_of => String, :default => "root"
attribute :group, :kind_of => String, :default => "root"

attribute :confdir, :kind_of => String, :default => "/etc/consul"
attribute :datadir, :kind_of => String, :default => "/tmp/consul"

attribute :ipaddress, :kind_of => String, :default => "0.0.0.0"
attribute :cdomain, :kind_of => String, :default => "redborder.cluster"

attribute :dns_local_ip, :kind_of => Array

attribute :is_server, :kind_of => [TrueClass, FalseClass]

attribute :log_level, :kind_of => String, :default => "INFO"
