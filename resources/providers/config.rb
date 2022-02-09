# Cookbook Name:: rbcep
#
# Provider:: config
#
include RbCep::Helper

action :add do
  begin
    user = new_resource.user
    vault_nodes = new_resource.vault_nodes
    ips_nodes = new_resource.ips_nodes
    social_nodes = new_resource.social_nodes
    flow_nodes = new_resource.flow_nodes
    cep_port = new_resource.cep_port

    ipsync, netsync, ifsync, masksync = get_sync
    dimensions = {}
    Dir.glob('/var/rb-extensions/*/dimensions.yml') do |item|
      dimensions = dimensions.merge(YAML.load_file(item)) rescue dimensions
    end

    user user do
      action :create
    end

    yum_package "redborder-cep" do
      action :upgrade
      flush_cache[:before]
    end

    directory "/etc/redborder-cep" do
      owner "redborder-cep"
      group "redborder-cep"
      mode 0770
      action :create
    end

    template "/etc/redborder-cep/config.yml" do
      source "cep_config.yml.erb"
      owner "root"
      group "root"
      mode 0644
      retries 2
      variables(:cep_port => cep_port, :ipsync => ipsync, :flow_nodes => flow_nodes, :social_nodes => social_nodes, :vault_nodes => vault_nodes, :ips_nodes => ips_nodes, :dimensions => dimensions )
      cookbook "rbcep"
      notifies :restart, "service[redborder-cep]", :delayed
    end

    template "/etc/redborder-cep/log4j2.xml" do
      source "cep_log4j2.xml.erb"
      owner "root"
      group "root"
      mode 0644
      retries 2
      cookbook "rbcep"
      notifies :restart, "service[redborder-cep]", :delayed
    end

    service "redborder-cep" do
      service_name "redborder-cep"
      ignore_failure true
      supports :status => true, :restart => true
      action [:enable, :start]
    end

    Chef::Log.info("cookbook redborder-cep has been processed.")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin

    service "redborder-cep" do
      supports :stop => true
      action :stop
    end

    %w[ /etc/redborder-cep].each do |path|
      directory path do
        recursive true
        action :delete
      end
    end
    # uninstall package
    yum_package "redborder-cep" do
      action :remove
    end

    Chef::Log.info("redborder-cep has been deleted correctly.")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do #Usually used to register in consul
  begin
    if !node["redborder-cep"]["registered"]
      query = {}
      query["ID"] = "redborder-cep-#{node["hostname"]}"
      query["Name"] = "redborder-cep"
      query["Address"] = "#{node["ipaddress"]}"
      query["Port"] = 443
      json_query = Chef::JSONCompat.to_json(query)

      execute 'Register service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.set["redborder-cep"]["registered"] = true
    end
    Chef::Log.info("redborder-cep service has been registered in consul")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :deregister do #Usually used to deregister from consul
  begin
    if node["redborder-cep"]["registered"]
      execute 'Deregister service in consul' do
        command "curl http://localhost:8500/v1/agent/service/deregister/redborder-cep-#{node["hostname"]} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.set["redborder-cep"]["registered"] = false
    end
    Chef::Log.info("redborder-cep service has been deregistered from consul")
  rescue => e
    Chef::Log.error(e.message)
  end
end