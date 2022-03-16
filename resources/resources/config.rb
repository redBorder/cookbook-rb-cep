#Cookbook Name :: rbcep
#
# Resource:: config
#
actions :add, :remove, :register, :deregister
default_action :add

attribute :memory, :kind_of => Fixnum, :default => 524288
attribute :user, :kind_of => String, :default => "redborder-cep"
attribute :log_dir, :kind_of => String, :default => "/var/log/redborder-cep"
attribute :cep_port, :kind_of => Fixnum, :default => 8888
attribute :vault_nodes, :kind_of => Object, :default => []
attribute :ips_nodes, :kind_of => Object, :default => []
attribute :flow_nodes, :kind_of => Object, :default => []
attribute :social_nodes, :kind_of => Object, :default => []