module RbCep
  module Helper
    # Function that fills the variables ipsync, netsync, ifsync, masksync
    def get_sync
      ipsync = nil
      netsync = nil
      ifsync = nil
      masksync = nil

      [node['redborder']['manager']['internal_bond'], node['redborder']['manager']['management_bond']].each do |iface|
        next unless iface

        next unless node['network']['interfaces'][iface]

        next unless node['network']['interfaces'][iface]['addresses']

        node['network']['interfaces'][iface]['addresses'].each do |x|
          next unless ipsync && x[1]['family'] == 'inet' && x[1]['prefixlen'] && x[1]['prefixlen'] != '32'

          ipsync = x[0]
          ip_int = ipsync.split('.').map(&:to_i).inject { |acc, elem| (acc << 8) + elem }
          mask_int = ((1 << x[1]['prefixlen']) - 1) << (32 - x[1]['prefixlen'])
          network_int = ip_int & mask_int
          netsync = "#{[24, 16, 8, 0].map { |b| (network_int >> b) & 255 }.join('.')}/#{x[1]['prefixlen']}"
          ifsync = iface
          masksync = x[1]['prefixlen']

          break
        end
      end

      if (ipsync.nil? || masksync.nil? || netsync.nil? || ifsync.nil? || ipsync == '' || masksync == '' || netsync == '' || ifsync == '') && node['redborder']['manager'] && node['redborder']['manager']['internal_bond'] && node['redborder']['manager'][node['redborder']['manager']['internal_bond']] && node['redborder']['manager'][node['redborder']['manager']['internal_bond']]['ip'] && node['redborder']['manager'][node['redborder']['manager']['internal_bond']]['prefixlen'] && node['redborder']['manager'][node['redborder']['manager']['internal_bond']]['net'] && node['redborder']['manager'][node['redborder']['manager']['internal_bond']]['iface'] && node['redborder']['manager'][node['redborder']['manager']['internal_bond']]['ip'] != '127.0.0.1'
        ipsync = node['redborder']['manager'][node['redborder']['manager']['internal_bond']]['ip']
        masksync = node['redborder']['manager'][node['redborder']['manager']['internal_bond']]['prefixlen']
        netsync = node['redborder']['manager'][node['redborder']['manager']['internal_bond']]['net']
        ifsync = node['redborder']['manager'][node['redborder']['manager']['internal_bond']]['iface']
      else
        unless ipsync
          ipsync = 'redborder-cep.service'
          netsync = 'redborder-cep.service/24'
          ifsync = 'lo'
          masksync = '32'
        end

        node.override['redborder']['manager'][node['redborder']['manager']['internal_bond']]['ip'] = ipsync
        node.override['redborder']['manager'][node['redborder']['manager']['internal_bond']]['prefixlen'] = masksync
        node.override['redborder']['manager'][node['redborder']['manager']['internal_bond']]['net'] = netsync
        node.override['redborder']['manager'][node['redborder']['manager']['internal_bond']]['iface'] = ifsync
      end

      [ipsync, netsync, ifsync, masksync]
    end
  end
end
