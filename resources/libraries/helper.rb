require 'netaddr'

module RbCep
  module Helper

    # Function that fills the variables ipsync, netsync, ifsync, masksync
    #
    def get_sync
      ipsync = nil
      netsync = nil
      ifsync = nil
      masksync = nil

      [ node["redborder"]["manager"]["internal_bond"], node["redborder"]["manager"]["management_bond"] ].each do |iface|
        unless iface.nil?
          unless node["network"]["interfaces"][iface].nil?
            unless node["network"]["interfaces"][iface]["addresses"].nil?
              node["network"]["interfaces"][iface]["addresses"].each do |x|
                if x[1]["family"] == "inet" and ipsync.nil? and !x[1]["prefixlen"].nil? and x[1]["prefixlen"] != "32"
                  ipsync = x[0]
                  netsync = NetAddr::CIDR.create("#{ipsync}/#{x[1]["prefixlen"]}").to_s
                  ifsync = iface
                  masksync = x[1]["prefixlen"]
                  break
                end
              end
            end
          end
        end
      end

      if (ipsync.nil? or masksync.nil? or netsync.nil? or ifsync.nil? or ipsync=="" or masksync=="" or netsync=="" or ifsync=="") and !node["redborder"]["manager"].nil? and !node["redborder"]["manager"]["internal_bond"].nil? and !node["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]].nil? and !node["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]]["ip"].nil? and !node["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]]["prefixlen"].nil? and !node["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]]["net"].nil? and !node["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]]["iface"].nil? and node["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]]["ip"] != "127.0.0.1"
        ipsync = node["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]]["ip"]
        masksync = node["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]]["prefixlen"]
        netsync = node["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]]["net"]
        ifsync = node["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]]["iface"]
      else
        if ipsync.nil?
          ipsync = "redborder-cep.service"
          netsync = "redborder-cep.service/24"
          ifsync = "lo"
          masksync = "32"
        end

        node.set["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]]["ip"] = ipsync
        node.set["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]]["prefixlen"] = masksync
        node.set["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]]["net"] = netsync
        node.set["redborder"]["manager"][node["redborder"]["manager"]["internal_bond"]]["iface"] = ifsync
      end

      [ipsync, netsync, ifsync, masksync]
    end

  end
end
