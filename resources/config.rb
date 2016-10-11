# Cookbook Name:: Consul
#
# Resource:: config
#

actions :add, :remove
default_action :add

attribute :user, :kind_of => String, :default => "consul"
attribute :group, :kind_of => String, :default => "consul"
attribute :logdir, :kind_of => String, :default => "/var/log/consul"
attribute :confdir, :kind_of => String, :default => "/etc/consul"
