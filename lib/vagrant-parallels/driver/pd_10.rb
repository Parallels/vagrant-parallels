require 'log4r'

require 'vagrant/util/platform'

require_relative 'pd_9'

module VagrantPlugins
  module Parallels
    module Driver
      # Driver for Parallels Desktop 10.
      class PD_10 < PD_9
        def initialize(uuid)
          super(uuid)

          @logger = Log4r::Logger.new('vagrant_parallels::driver::pd_10')
        end

        def clear_forwarded_ports
          args = []
          read_forwarded_ports.each do |r|
            args.concat(["--nat-#{r[:protocol]}-del", r[:rule_name]])
          end

          if !args.empty?
            execute_prlsrvctl('net', 'set', read_shared_network_id, *args)
          end
        end


        def delete_unused_host_only_networks
          networks = read_virtual_networks
          # 'Shared'(vnic0) and 'Host-Only'(vnic1) are default in Parallels Desktop
          # They should not be deleted anyway.
          networks.keep_if do |net|
            net['Type'] == 'host-only' &&
              net['Bound To'].match(/^(?>vnic|Parallels Host-Only #)(\d+)$/)[1].to_i >= 2
          end

          read_vms_info.each do |vm|
            used_nets = vm.fetch('Hardware', {}).select { |name, _| name.start_with? 'net' }
            used_nets.each_value do |net_params|
              networks.delete_if { |net| net['Network ID'] == net_params.fetch('iface', nil) }
            end
          end

          networks.each do |net|
            # Delete the actual host only network interface.
            execute_prlsrvctl('net', 'del', net['Network ID'])
          end
        end

        def disable_password_restrictions(acts)
          server_info = json { execute_prlsrvctl('info', '--json') }
          server_info.fetch('Require password to',[]).each do |act|
            execute_prlsrvctl('set', '--require-pwd', "#{act}:off") if acts.include? act
          end
        end

        def enable_adapters(adapters)
          # Get adapters which have already configured for this VM
          # Such adapters will be just overridden
          existing_adapters = read_settings.fetch('Hardware', {}).keys.select do |name|
            name.start_with? 'net'
          end

          # Disable all previously existing adapters (except shared 'vnet0')
          existing_adapters.each do |adapter|
            if adapter != 'vnet0'
              execute_prlctl('set', @uuid, '--device-set', adapter, '--disable')
            end
          end

          adapters.each do |adapter|
            args = []
            if existing_adapters.include? "net#{adapter[:adapter]}"
              args.concat(['--device-set',"net#{adapter[:adapter]}", '--enable'])
            else
              args.concat(['--device-add', 'net'])
            end

            if adapter[:type] == :hostonly
              args.concat(['--type', 'host', '--iface', adapter[:hostonly]])
            elsif adapter[:type] == :bridged
              args.concat(['--type', 'bridged', '--iface', adapter[:bridge]])
            elsif adapter[:type] == :shared
              args.concat(['--type', 'shared'])
            end

            if adapter[:mac_address]
              args.concat(['--mac', adapter[:mac_address]])
            end

            if adapter[:nic_type]
              args.concat(['--adapter-type', adapter[:nic_type].to_s])
            end

            execute_prlctl('set', @uuid, *args)
          end
        end

        def forward_ports(ports)
          args = []
          ports.each do |options|
            protocol = options[:protocol] || 'tcp'
            pf_builder = [
              options[:name],
              options[:hostport],
              @uuid,
              options[:guestport]
            ]

            args.concat(["--nat-#{protocol}-add", pf_builder.join(',')])
          end

          execute_prlsrvctl('net', 'set', read_shared_network_id, *args)
        end

        def read_forwarded_ports(global=false)
          all_rules = read_shared_interface[:nat]

          if global
            all_rules
          else
            all_rules.select { |r| r[:guest].include?(@uuid) }
          end
        end

        def read_host_only_interfaces
          net_list = read_virtual_networks
          net_list.keep_if { |net| net['Type'] == 'host-only' }

          hostonly_ifaces = []
          net_list.each do |iface|
            info = {}
            net_info = json { execute_prlsrvctl('net', 'info', iface['Network ID'], '--json') }
            adapter = net_info['Parallels adapter']

            info[:name]     = net_info['Network ID']
            info[:bound_to] = net_info['Bound To']
            # In PD >= 10.1.2 there are new field names for an IP/Subnet
            info[:ip]       = adapter['IP address'] || adapter['IPv4 address']
            info[:netmask]  = adapter['Subnet mask'] || adapter['IPv4 subnet mask']

            # Such interfaces are always in 'Up'
            info[:status]   = 'Up'

            # There may be a fake DHCPv4 parameters
            # We can trust them only if adapter IP and DHCP IP are in the same subnet
            dhcp_info = net_info['DHCPv4 server']
            if dhcp_info && (network_address(info[:ip], info[:netmask]) ==
              network_address(dhcp_info['Server address'], info[:netmask]))
              info[:dhcp] = {
                ip:    dhcp_info['Server address'],
                lower: dhcp_info['IP scope start address'],
                upper: dhcp_info['IP scope end address']
              }
            end
            hostonly_ifaces << info
          end
          hostonly_ifaces
        end

        def read_network_interfaces
          nics = {}

          # Get enabled VM's network interfaces
          ifaces = read_settings.fetch('Hardware', {}).keep_if do |dev, params|
            dev.start_with?('net') and params.fetch('enabled', true)
          end
          ifaces.each do |name, params|
            adapter = name.match(/^net(\d+)$/)[1].to_i
            nics[adapter] ||= {}

            if params['type'] == 'shared'
              nics[adapter][:type] = :shared
            elsif params['type'] == 'host'
              nics[adapter][:type] = :hostonly
              nics[adapter][:hostonly] = params.fetch('iface','')
            elsif params['type'] == 'bridged'
              nics[adapter][:type] = :bridged
              nics[adapter][:bridge] = params.fetch('iface','')
            end
          end
          nics
        end

        def read_shared_interface
          net_info = json do
            execute_prlsrvctl('net', 'info', read_shared_network_id, '--json')
          end

          adapter = net_info['Parallels adapter']

          # In PD >= 10.1.2 there are new field names for an IP/Subnet
          info = {
            name:    net_info['Bound To'],
            ip:      adapter['IP address'] || adapter['IPv4 address'],
            netmask: adapter['Subnet mask'] || adapter['IPv4 subnet mask'],
            status:  'Up',
            nat:     []
          }

          if net_info.key?('DHCPv4 server')
            info[:dhcp] = {
              ip:    net_info['DHCPv4 server']['Server address'],
              lower: net_info['DHCPv4 server']['IP scope start address'],
              upper: net_info['DHCPv4 server']['IP scope end address']
            }
          end

          net_info['NAT server'].each do |group, rules|
            rules.each do |name, params|
              info[:nat] << {
                rule_name: name,
                protocol:  group == 'TCP rules' ? 'tcp' : 'udp',
                guest:     params['destination IP/VM id'],
                hostport:  params['source port'],
                guestport: params['destination port']
              }
            end
          end

          info
        end

        def read_used_ports
          # Ignore our own used ports
          read_forwarded_ports(true).reject { |r| r[:guest].include?(@uuid) }
        end
      end
    end
  end
end
