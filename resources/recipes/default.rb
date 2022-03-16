#
# Cookbook Name:: rbcep
# Recipe:: default
#
# redborder
#
#

rbcep_config "config" do
  name node["hostname"]
  action :add
end
