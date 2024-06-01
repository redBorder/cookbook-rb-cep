# Cookbook:: rbcep
# Provider:: config

include RbCep::Helper

action :add do
  begin
    vault_nodes = new_resource.vault_nodes
    ips_nodes = new_resource.ips_nodes
    flow_nodes = new_resource.flow_nodes
    cep_port = new_resource.cep_port
    log_dir = new_resource.log_dir

    ipsync, _netsync, _ifsync, _masksync = get_sync
    dimensions = {}
    Dir.glob('/var/rb-extensions/*/dimensions.yml') do |item|
      begin
        dimensions.merge!(YAML.load_file(item))
      rescue StandarError => e
        puts "Error loading #{item}: #{e.message}"
        dimensions
      end
    end

    dnf_package 'redborder-cep' do
      action :upgrade
      flush_cache[:before]
    end

    directory '/etc/redborder-cep' do
      owner 'root'
      group 'root'
      mode '0770'
      action :create
    end

    directory log_dir do
      owner 'root'
      group 'root'
      mode '0755'
    end

    template '/etc/redborder-cep/config.yml' do
      source 'cep_config.yml.erb'
      owner 'root'
      group 'root'
      mode '0644'
      retries 2
      variables(cep_port: cep_port, ipsync: ipsync,
                flow_nodes: flow_nodes, vault_nodes: vault_nodes,
                ips_nodes: ips_nodes, dimensions: dimensions)
      cookbook 'rbcep'
      notifies :restart, 'service[redborder-cep]', :delayed
    end

    template '/etc/redborder-cep/log4j2.xml' do
      source 'cep_log4j2.xml.erb'
      owner 'root'
      group 'root'
      mode '0644'
      retries 2
      cookbook 'rbcep'
      notifies :restart, 'service[redborder-cep]', :delayed
    end

    service 'redborder-cep' do
      service_name 'redborder-cep'
      ignore_failure true
      supports status: true, restart: true
      action [:enable, :start]
    end

    Chef::Log.info('cookbook redborder-cep has been processed.')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    service 'redborder-cep' do
      supports stop: true
      action :stop
    end

    %w(/etc/redborder-cep).each do |path|
      directory path do
        recursive true
        action :delete
      end
    end
    # uninstall package
    dnf_package 'redborder-cep' do
      action :remove
    end

    Chef::Log.info('redborder-cep has been deleted correctly.')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do
  begin
    unless node['redborder-cep']['registered']
      query = {}
      query['ID'] = "redborder-cep-#{node['hostname']}"
      query['Name'] = 'redborder-cep'
      query['Address'] = "#{node['ipaddress']}"
      query['Port'] = 443
      json_query = Chef::JSONCompat.to_json(query)

      execute 'Register service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['redborder-cep']['registered'] = true
      Chef::Log.info('redborder-cep service has been registered in consul')
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :deregister do
  begin
    if node['redborder-cep']['registered']
      execute 'Deregister service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/deregister/redborder-cep-#{node['hostname']} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['redborder-cep']['registered'] = false
      Chef::Log.info('redborder-cep service has been deregistered from consul')
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end
