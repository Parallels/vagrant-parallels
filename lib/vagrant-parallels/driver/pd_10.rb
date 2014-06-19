require 'log4r'

require 'vagrant/util/platform'

require File.expand_path('../pd_9', __FILE__)

module VagrantPlugins
  module Parallels
    module Driver
      # Driver for Parallels Desktop 10.
      class PD_10 < PD_9
        def initialize(uuid)
          super(uuid)

          @logger = Log4r::Logger.new('vagrant::provider::parallels::pd_10')
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

        def read_shared_interface
          net_info = json do
            execute_prlsrvctl('net', 'info', read_shared_network_id, '--json')
          end
          info = {
            name:    net_info['Bound To'],
            ip:      net_info['Parallels adapter']['IP address'],
            netmask: net_info['Parallels adapter']['Subnet mask'],
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

        def read_forwarded_ports(global=false)
          all_rules = read_shared_interface[:nat]

          if global
            all_rules
          else
            all_rules.select { |r| r[:guest].include?(@uuid) }
          end
        end

        # Parse the JSON from *all* VMs and templates.
        # Then return an array of objects (without duplicates)
        def read_vms_info
          vms_arr = json([]) do
            execute_prlctl('list', '--all','--info', '--json')
          end
          templates_arr = json([]) do
            execute_prlctl('list', '--all','--info', '--json', '--template')
          end
          vms_arr | templates_arr
        end

        def read_used_ports
          # Ignore our own used ports
          read_forwarded_ports(true).reject { |r| r[:guest].include?(@uuid) }
        end

        def set_power_consumption_mode(optimized)
          state = optimized ? 'on' : 'off'
          execute_prlctl('set', @uuid, '--longer-battery-life', state)
        end

        def ssh_ip
          '127.0.0.1'
        end

        def ssh_port(expected_port)
          @logger.debug("Searching for SSH port: #{expected_port.inspect}")

          # Look for the forwarded port only by comparing the guest port
          read_forwarded_ports.each do |r|
            return r[:hostport] if r[:guestport] == expected_port
          end

          nil
        end
      end
    end
  end
end
