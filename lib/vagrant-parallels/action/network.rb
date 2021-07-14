require 'ipaddr'
require 'set'
require 'log4r'

require 'vagrant/util/scoped_hash_override'

module VagrantPlugins
  module Parallels
    module Action
      # This middleware class sets up all networking for the Parallels Desktop
      # instance. This includes host only networks, bridged networking,
      # forwarded ports, etc.
      #
      # This handles all the `config.vm.network` configurations.
      class Network
        include Vagrant::Util::ScopedHashOverride
        @@lock = Mutex.new

        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::network')
        end

        def call(env)
          @env = env

          # Get the list of network adapters from the configuration
          network_adapters_config = env[:machine].provider_config.network_adapters.dup

          # Assign the adapter slot for each high-level network
          available_slots = Set.new(0...16)
          network_adapters_config.each do |slot, _data|
            available_slots.delete(slot)
          end

          @logger.debug("Available slots for high-level adapters: #{available_slots.inspect}")
          @logger.info('Determining network adapters required for high-level configuration...')
          available_slots = available_slots.to_a.sort
          env[:machine].config.vm.networks.each do |type, options|
            # We only handle private and public networks
            next if type != :private_network && type != :public_network

            options = scoped_hash_override(options, :parallels)

            # Figure out the slot that this adapter will go into
            slot = options[:adapter]
            unless slot
              raise VagrantPlugins::Parallels::Errors::ParallelsNoRoomForHighLevelNetwork if available_slots.empty?

              slot = available_slots.shift
            end

            # Configure it
            data = nil
            #noinspection RubyCaseWithoutElseBlockInspection
            case type
            when :private_network
              # private_network = hostonly
              data = [:hostonly, options]
            when :public_network
              # public_network = bridged
              data = [:bridged, options]
            end

            # Store it!
            @logger.info(" -- Slot #{slot}: #{data[0]}")
            network_adapters_config[slot] = data
          end

          @logger.info('Determining adapters and compiling network configuration...')
          adapters = []
          networks = []
          network_adapters_config.each do |slot, data|
            type    = data[0]
            options = data[1]

            @logger.info("Network slot #{slot}. Type: #{type}.")

            # Get the normalized configuration for this type
            config = send("#{type}_config", options)
            config[:adapter] = slot
            @logger.debug("Normalized configuration: #{config.inspect}")

            # Get the virtual network adapter configuration
            # We wrap this in locks to avoid race conditions between multiple
            # Vagrant threads and/or processes.
            @@lock.synchronize do
              begin
                env[:machine].env.lock('parallels-network-adapters') do
                  adapter = send("#{type}_adapter", config)
                  adapters << adapter
                  @logger.debug("Adapter configuration: #{adapter.inspect}")
                end
              rescue Vagrant::Errors::EnvironmentLockedError
                sleep 1
                retry
              end
            end

            # Get the network configuration
            network = send("#{type}_network_config", config)
            network[:auto_config] = config[:auto_config]
            networks << network
          end

          unless adapters.empty?
            # Enable the adapters
            @logger.info('Enabling adapters...')
            env[:ui].output(I18n.t('vagrant.actions.vm.network.preparing'))
            adapters.each do |adapter|
              env[:ui].detail(I18n.t('vagrant_parallels.parallels.network_adapter',
                                     adapter: adapter[:adapter].to_s,
                                     type: adapter[:type].to_s,
                                     extra: '',
              ))
            end

            env[:machine].provider.driver.enable_adapters(adapters)
          end

          # Continue the middleware chain.
          @app.call(env)

          # If we have networks to configure, then we configure it now, since
          # that requires the machine to be up and running.
          unless adapters.empty? && networks.empty?
            assign_interface_numbers(networks, adapters)

            # Only configure the networks the user requested us to configure
            networks_to_configure = networks.select { |n| n[:auto_config] }
            unless networks_to_configure.empty?
              env[:ui].info I18n.t('vagrant.actions.vm.network.configuring')
              env[:machine].guest.capability(:configure_networks, networks_to_configure)
            end
          end
        end

        def bridged_config(options)
          {
            auto_config: true,
            bridge: nil,
            mac: nil,
            nic_type: nil,
            use_dhcp_assigned_default_route: false
          }.merge(options || {})
        end

        def bridged_adapter(config)
          # Find the bridged interfaces that are available
          bridgedifs = @env[:machine].provider.driver.read_bridged_interfaces
          bridgedifs.delete_if { |interface| interface[:status] == 'Down' }

          # The name of the chosen bridge interface will be assigned to this
          # variable.
          chosen_bridge = nil

          if config[:bridge]
            @logger.debug("Bridge was directly specified in config, searching for: #{config[:bridge]}")

            # Search for a matching bridged interface
            Array(config[:bridge]).each do |bridge|
              bridge = bridge.downcase if bridge.respond_to?(:downcase)
              bridgedifs.each do |interface|
                next unless bridge === interface[:name].downcase

                @logger.debug('Specific bridge found as configured in the Vagrantfile. Using it.')
                chosen_bridge = interface[:name]
                break
              end
              break if chosen_bridge
            end

            # If one wasn't found, then we notify the user here.
            unless chosen_bridge
              @env[:ui].info I18n.t(
                'vagrant.actions.vm.bridged_networking.specific_not_found',
                bridge: config[:bridge])
            end
          end

          # If we still don't have a bridge chosen (this means that one wasn't
          # specified in the Vagrantfile, or the bridge specified in the Vagrantfile
          # wasn't found), then we fall back to the normal means of searching for a
          # bridged network.
          unless chosen_bridge
            if bridgedifs.length == 1
              # One bridgable interface? Just use it.
              chosen_bridge = bridgedifs[0][:name]
              @logger.debug('Only one bridged interface available. Using it by default.')
            else
              # More than one bridgable interface requires a user decision, so
              # show options to choose from.
              @env[:ui].info I18n.t(
                'vagrant.actions.vm.bridged_networking.available', prefix: false)
              bridgedifs.each_index do |index|
                interface = bridgedifs[index]
                @env[:ui].info("#{index + 1}) #{interface[:name]}", prefix: false)
              end
              @env[:ui].info("#{I18n.t('vagrant.actions.vm.bridged_networking.choice_help')}\n")

              # The range of valid choices
              valid = Range.new(1, bridgedifs.length)

              # The choice that the user has chosen as the bridging interface
              choice = nil
              until valid.include?(choice)
                choice = @env[:ui].ask(
                  'Which interface should the network bridge to? Enter a number: ')
                choice = choice.to_i
              end

              chosen_bridge = bridgedifs[choice - 1][:name]
            end
          end

          @logger.info("Bridging adapter #{config[:adapter]} to #{chosen_bridge}")

          # Given the choice we can now define the adapter we're using
          {
            adapter: config[:adapter],
            type: :bridged,
            bridge: chosen_bridge,
            mac_address: config[:mac],
            nic_type: config[:nic_type]
          }
        end

        def bridged_network_config(config)
          if config[:ip]
            options = {
              auto_config: true,
              mac: nil,
              netmask: '255.255.255.0',
              type: :static
            }.merge(config)
            options[:type] = options[:type].to_sym
            return options
          end

          {
            type: :dhcp,
            use_dhcp_assigned_default_route: config[:use_dhcp_assigned_default_route]
          }
        end

        def hostonly_config(options)
          options = {
            auto_config: true,
            mac: nil,
            name: nil,
            nic_type: nil,
            type: :static
          }.merge(options)

          # Make sure the type is a symbol
          options[:type] = options[:type].to_sym

          # Default IP is in the 20-bit private network block for DHCP based networks
          options[:ip] = '10.37.129.1' if options[:type] == :dhcp && !options[:ip]

          begin
            ip = IPAddr.new(options[:ip])
            if ip.ipv4?
              options[:netmask] ||= '255.255.255.0'
            elsif ip.ipv6?
              options[:netmask] ||= 64

              # Append a 6 to the end of the type
              options[:type] = "#{options[:type]}6".to_sym
            else
              raise IPAddr::AddressFamilyError, 'unknown address family'
            end

            # Calculate our network address for the given IP/netmask
            netaddr = IPAddr.new("#{options[:ip]}/#{options[:netmask]}")
          rescue IPAddr::Error => e
            raise VagrantPlugins::Parallels::Errors::NetworkInvalidAddress,
                  options: options, error: e.message
          end

          if ip.ipv4?
            # Verify that a host-only network subnet would not collide
            # with a bridged networking interface.
            #
            # If the subnets overlap in any way then the host only network
            # will not work because the routing tables will force the
            # traffic onto the real interface rather than the virtual
            # network interface.
            @env[:machine].provider.driver.read_bridged_interfaces.each do |interface|
              next if interface[:status] == 'Down'

              that_netaddr = IPAddr.new("#{interface[:ip]}/#{interface[:netmask]}")
              next unless netaddr.include? that_netaddr

              raise VagrantPlugins::Parallels::Errors::NetworkCollision,
                    hostonly_netaddr: netaddr,
                    bridge_netaddr: that_netaddr,
                    bridge_interface: interface[:name]
            end
          end

          # Calculate the adapter IP which is the network address with the final
          # bit group appended by 1. Usually it is "x.x.x.1" for IPv4 and
          # "<prefix>::1" for IPv6
          options[:adapter_ip] ||= (netaddr | 1).to_s

          dhcp_options = {}
          if options[:type] == :dhcp
            # Calculate the IP and lower & upper bound for the DHCP server
            # Example: for "192.168.22.64/26" network range it wil be:
            # dhcp_ip: "192.168.22.65",
            # dhcp_lower: "192.168.22.66"
            # dhcp_upper: "192.168.22.126"
            ip_range = netaddr.to_range
            dhcp_options[:dhcp_ip]    = options[:dhcp_ip]    || (ip_range.first | 1).to_s
            dhcp_options[:dhcp_lower] = options[:dhcp_lower] || (ip_range.first | 2).to_s
            dhcp_options[:dhcp_upper] = options[:dhcp_upper] || (ip_range.last(2).first).to_s
          end

          {
            adapter_ip: options[:adapter_ip],
            auto_config: options[:auto_config],
            ip: options[:ip],
            mac: options[:mac],
            name: options[:name],
            netmask: options[:netmask],
            nic_type: options[:nic_type],
            type: options[:type]
          }.merge(dhcp_options)
        end

        def hostonly_adapter(config)
          @logger.info("Searching for matching hostonly network: #{config[:ip]}")
          interface = hostonly_find_matching_network(config)

          unless interface
            @logger.info('Network not found. Creating if we can.')

            # Create a new network
            interface = hostonly_create_network(config)
            @logger.info("Created network: #{interface[:name]}")
          end

          {
            adapter: config[:adapter],
            hostonly: interface[:name],
            mac_address: config[:mac],
            nic_type: config[:nic_type],
            type: :hostonly
          }
        end

        def hostonly_network_config(config)
          {
            type: config[:type],
            adapter_ip: config[:adapter_ip],
            ip: config[:ip],
            netmask: config[:netmask]
          }
        end


        def shared_config(_options)
          {
            auto_config: false
          }
        end

        def shared_adapter(config)
          {
            adapter: config[:adapter],
            type: :shared
          }
        end

        def shared_network_config(_config)
          {}
        end

        #-----------------------------------------------------------------
        # Misc. helpers
        #-----------------------------------------------------------------
        # Assigns the actual interface number of a network based on the
        # enabled NICs on the virtual machine.
        #
        # This interface number is used by the guest to configure the
        # NIC on the guest VM.
        #
        # The networks are modified in place by adding an ":interface"
        # field to each.
        def assign_interface_numbers(networks, adapters)
          current = 0
          adapter_to_interface = {}

          # Make a first pass to assign interface numbers by adapter location
          vm_adapters = @env[:machine].provider.driver.read_network_interfaces
          vm_adapters.sort.each do |number, adapter|
            next unless adapter[:type] != :none

            # Not used, so assign the interface number and increment
            adapter_to_interface[number] = current
            current += 1
          end

          # Make a pass through the adapters to assign the :interface
          # key to each network configuration.
          adapters.each_index do |i|
            adapter = adapters[i]
            network = networks[i]

            # Figure out the interface number by simple lookup
            network[:interface] = adapter_to_interface[adapter[:adapter]]
          end
        end

        # This determines the next free network name
        def next_network_id
          # Get the list of numbers
          net_nums = []
          @env[:machine].provider.driver.read_virtual_networks.each do |net|
            net_nums << $1.to_i if net['Network ID'] =~ /^vagrant-vnet(\d+)$/
          end

          if net_nums.empty?
            'vagrant-vnet0'
          else
            free_names = Array(0..net_nums.max.next) - net_nums
            "vagrant-vnet#{free_names.first}"
          end
        end

        #-----------------------------------------------------------------
        # Hostonly Helper Functions
        #-----------------------------------------------------------------
        # This creates a host only network for the given configuration.
        def hostonly_create_network(config)
          options = {
            network_id: config[:name] || next_network_id,
            adapter_ip: config[:adapter_ip],
            netmask: config[:netmask],
          }

          if config[:type] == :dhcp
            options[:dhcp] = {
              ip: config[:dhcp_ip],
              lower: config[:dhcp_lower],
              upper: config[:dhcp_upper]
            }
          end

          @env[:machine].provider.driver.create_host_only_network(options)
        end

        # This finds a matching host only network for the given configuration.
        def hostonly_find_matching_network(config)
          this_netaddr = IPAddr.new("#{config[:ip]}/#{config[:netmask]}")

          @env[:machine].provider.driver.read_host_only_interfaces.each do |interface|
            return interface if config[:name] && config[:name] == interface[:name]

            if interface[:ip] && this_netaddr.ipv4?
              netaddr = IPAddr.new("#{interface[:ip]}/#{interface[:netmask]}")
              return interface if netaddr.include? this_netaddr
            end

            if interface[:ipv6] && this_netaddr.ipv6?
              netaddr = IPAddr.new("#{interface[:ipv6]}/#{interface[:ipv6_prefix]}")
              return interface if netaddr.include? this_netaddr
            end
          end

          nil
        end
      end
    end
  end
end
