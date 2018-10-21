require 'log4r'

require 'vagrant/util/platform'

require_relative 'pd_11'

module VagrantPlugins
  module Parallels
    module Driver
      # Driver for Parallels Desktop 12 and later.
      class PD_12 < PD_11
        def initialize(uuid)
          super(uuid)

          @logger = Log4r::Logger.new('vagrant_parallels::driver::pd_12')
        end

        def create_host_only_network(options)
          # Create the interface
          execute_prlsrvctl('net', 'add', options[:network_id], '--type', 'host-only')

          # Get the IP so we can determine v4 vs v6
          ip = IPAddr.new(options[:adapter_ip])
          if ip.ipv4?
            args = ['--ip', "#{options[:adapter_ip]}/#{options[:netmask]}"]
            if options[:dhcp]
              args.concat(['--dhcp-ip', options[:dhcp][:ip],
                           '--ip-scope-start', options[:dhcp][:lower],
                           '--ip-scope-end', options[:dhcp][:upper]])
            end
          elsif ip.ipv6?
            # Convert prefix length to netmask ("32" -> "ffff:ffff::")
            options[:netmask] = IPAddr.new(IPAddr::IN6MASK, Socket::AF_INET6)
                                  .mask(options[:netmask]).to_s

            args = ['--host-assign-ip6', 'on',
                    '--ip6', "#{options[:adapter_ip]}/#{options[:netmask]}"]
            # DHCPv6 setting is not supported by Vagrant yet.
          else
            raise IPAddr::AddressFamilyError, 'BUG: unknown address family'
          end

          execute_prlsrvctl('net', 'set', options[:network_id], *args)

          # Return the details
          {
            name:    options[:network_id],
            ip:      options[:adapter_ip],
            netmask: options[:netmask],
            dhcp:    options[:dhcp]
          }
        end
      end
    end
  end
end
