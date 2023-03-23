require 'log4r'
require 'nokogiri'

require 'vagrant/util/busy'
require 'vagrant/util/network_ip'
require 'vagrant/util/platform'
require 'vagrant/util/retryable'
require 'vagrant/util/subprocess'
require 'vagrant/util/which'

module VagrantPlugins
  module Parallels
    module Driver
      # Base class for all Parallels drivers.
      #
      # This class provides useful tools for things such as executing
      # PrlCtl and handling SIGINTs and so on.
      class Base
        # Include this so we can use `Subprocess` more easily.
        include Vagrant::Util::Retryable
        include Vagrant::Util::NetworkIP

        def initialize(uuid)
          @uuid = uuid
          @logger = Log4r::Logger.new('vagrant_parallels::driver::base')

          # This flag is used to keep track of interrupted state (SIGINT)
          @interrupted = false

          @prlctl_path = util_path('prlctl')
          @prlsrvctl_path = util_path('prlsrvctl')
          @prldisktool_path = util_path('prl_disk_tool')

          unless @prlctl_path
            # This means that Parallels Desktop was not found, so we raise this
            # error here.
            raise VagrantPlugins::Parallels::Errors::ParallelsNotDetected
          end

          @logger.info("prlctl path: #{@prlctl_path}")
          @logger.info("prlsrvctl path: #{@prlsrvctl_path}")
        end

        # Removes the specified port forwarding rules for the virtual machine.
        #
        # @param [Array<Symbol => String>] ports - List of ports.
        # Each port should be described as a hash with the following keys:
        #
        #     {
        #       name:      'example',
        #       protocol:  'tcp',
        #       guest:     'target-vm-uuid',
        #       hostport:  '8080',
        #       guestport: '80'
        #     }
        #
        def clear_forwarded_ports(ports)
          args = []
          ports.each do |r|
            args.concat(["--nat-#{r[:protocol]}-del", r[:name]])
          end

          execute_prlsrvctl('net', 'set', read_shared_network_id, *args) unless args.empty?
        end

        # Clears the shared folders that have been set on the virtual machine.
        def clear_shared_folders
          share_ids = read_shared_folders.keys
          share_ids.each do |id|
            execute_prlctl('set', @uuid, '--shf-host-del', id)
          end
        end

        # Makes a clone of the virtual machine.
        #
        # @param [String] src_name Name or UUID of the source VM or template.
        # @param [<String => String>] options Options to clone virtual machine.
        # @return [String] UUID of the new VM.
        def clone_vm(src_name, options = {})
          dst_name = "vagrant_temp_#{(Time.now.to_f * 1000.0).to_i}_#{rand(100000)}"

          args = ['clone', src_name, '--name', dst_name]
          args.concat(['--dst', options[:dst]]) if options[:dst]

          # Linked clone options
          args << '--linked' if options[:linked]
          args.concat(['--id', options[:snapshot_id]]) if options[:snapshot_id]

          # Regenerate SourceVmUuid of the cloned VM
          args << '--regenerate-src-uuid' if options[:regenerate_src_uuid]

          execute_prlctl(*args) do |_, data|
            lines = data.split('\r')
            # The progress of the clone will be in the last line. Do a greedy
            # regular expression to find what we're looking for.
            if lines.last =~ /Copying hard disk.+?(\d{,3}) ?%/
              yield $1.to_i if block_given?
            end
          end
          read_vms[dst_name]
        end

        # Compacts the specified virtual disk image
        #
        # @param [<String>] hdd_path Path to the target '*.hdd'
        def compact_hdd(hdd_path)
          execute(@prldisktool_path, 'compact', '--hdd', hdd_path) do |_, data|
            lines = data.split('\r')
            # The progress of the compact will be in the last line. Do a greedy
            # regular expression to find what we're looking for.
            if lines.last =~ /.+?(\d{,3}) ?%/
              yield $1.to_i if block_given?
            end
          end
        end

        # Connects the host machine to the  specified virtual network interface
        # Could be used for Parallels' Shared and Host-Only interfaces only.
        #
        # @param [<String>] name Network interface name. Example: 'Shared'
        def connect_network_interface(name)
          raise NotImplementedError
        end

        # Creates a host only network with the given options.
        #
        # @param [<Symbol => String>] options Hostonly network options.
        # @return [<Symbol => String>] The details of the host only network,
        # including keys `:name`, `:ip`, `:netmask` and `:dhcp`
        # @param [<Symbol => String>] options
        def create_host_only_network(options)
          # Create the interface
          execute_prlsrvctl('net', 'add', options[:network_id], '--type', 'host-only')

          # Configure it
          args = ['--ip', "#{options[:adapter_ip]}/#{options[:netmask]}"]
          if options[:dhcp]
            args.concat(['--dhcp-ip', options[:dhcp][:ip],
                         '--ip-scope-start', options[:dhcp][:lower],
                         '--ip-scope-end', options[:dhcp][:upper]])
          end

          execute_prlsrvctl('net', 'set', options[:network_id], *args)

          # Return the details
          {
            name: options[:network_id],
            ip: options[:adapter_ip],
            netmask: options[:netmask],
            dhcp: options[:dhcp]
          }
        end

        # Creates a snapshot for the specified virtual machine.
        #
        # @param [String] uuid Name or UUID of the target VM
        # @param [String] snapshot_name Snapshot name
        # @return [String] ID of the created snapshot.
        def create_snapshot(uuid, snapshot_name)
          stdout = execute_prlctl('snapshot', uuid, '--name', snapshot_name)
          return Regexp.last_match(1) if stdout =~ /{([\w-]+)}/

          raise Errors::SnapshotIdNotDetected, stdout: stdout
        end

        # Deletes the virtual machine references by this driver.
        def delete
          execute_prlctl('delete', @uuid)
        end

        # Deletes all disabled network adapters from the VM configuration
        def delete_disabled_adapters
          read_settings.fetch('Hardware', {}).each do |adapter, params|
            if adapter.start_with?('net') and !params.fetch('enabled', true)
              execute_prlctl('set', @uuid, '--device-del', adapter)
            end
          end
        end

        # Deletes the specified snapshot
        #
        # @param [String] uuid Name or UUID of the target VM
        # @param [String] snapshot_id Snapshot ID
        def delete_snapshot(uuid, snapshot_id)
          # Sometimes this command fails with 'Data synchronization is currently
          # in progress'. Just wait and retry.
          retryable(on: VagrantPlugins::Parallels::Errors::ExecutionError, tries: 2, sleep: 2) do
            execute_prlctl('snapshot-delete', uuid, '--id', snapshot_id)
          end
        end

        # Deletes host-only networks that aren't being used by any virtual machine.
        def delete_unused_host_only_networks
          networks = read_virtual_networks

          # Exclude all host-only network interfaces which were not created by vagrant provider.
          networks.keep_if do |net|
            net['Type'] == 'host-only' && net['Network ID'] =~ /^vagrant-vnet(\d+)$/
          end

          read_vms_info.each do |vm|
            used_nets = vm.fetch('Hardware', {}).select { |name, _| name.start_with? 'net' }
            used_nets.each_value do |net_params|
              networks.delete_if { |net| net['Network ID'] == net_params.fetch('iface', nil) }
            end
          end

          # Delete all unused network interfaces.
          networks.each do |net|
            execute_prlsrvctl('net', 'del', net['Network ID'])
          end
        end

        # Disables requiring password on such operations as creating, adding,
        # removing or cloning the virtual machine.
        #
        # @param [Array<String>] acts List of actions. Available values:
        # ['create-vm', 'add-vm', 'remove-vm', 'clone-vm']
        def disable_password_restrictions(acts)
          server_info = json { execute_prlsrvctl('info', '--json') }
          server_info.fetch('Require password to', []).each do |act|
            execute_prlsrvctl('set', '--require-pwd', "#{act}:off") if acts.include? act
          end
        end

        # Enables network adapters on the VM.
        #
        # The format of each adapter specification should be like so:
        #
        # {
        #   :type     => :hostonly,
        #   :hostonly => "vagrant-vnet0",
        #   :name     => "vnic2",
        #   :nic_type => "virtio"
        # }
        #
        # This must support setting up both host only and bridged networks.
        #
        # @param [Array<Symbol => Symbol, String>] adapters
        # Array of adapters to be enabled.
        def enable_adapters(adapters)
          # Get adapters which have already configured for this VM
          # Such adapters will be just overridden
          existing_adapters = read_settings.fetch('Hardware', {}).keys.select do |name|
            name.start_with? 'net'
          end

          # Disable all previously existing adapters (except shared 'vnet0')
          existing_adapters.each do |adapter|
            execute_prlctl('set', @uuid, '--device-set', adapter, '--disable') if adapter != 'vnet0'
          end

          adapters.each do |adapter|
            args = []
            if existing_adapters.include? "net#{adapter[:adapter]}"
              args.concat(['--device-set', "net#{adapter[:adapter]}", '--enable'])
            else
              args.concat(%w[--device-add net])
            end

            case adapter[:type]
            when :hostonly
              args.concat(['--type', 'host', '--iface', adapter[:hostonly]])
            when :bridged
              args.concat(['--type', 'bridged', '--iface', adapter[:bridge]])
            when :shared
              args.concat(%w[--type shared])
            end

            args.concat(['--mac', adapter[:mac_address]]) if adapter[:mac_address]

            args.concat(['--adapter-type', adapter[:nic_type].to_s]) if adapter[:nic_type]

            execute_prlctl('set', @uuid, *args)
          end
        end

        # Create a set of port forwarding rules for a virtual machine.
        #
        # This will not affect any previously set forwarded ports,
        # so be sure to delete those if you need to.
        #
        # The format of each port hash should be the following:
        #
        #     {
        #       guestport: 80,
        #       hostport: 8500,
        #       name: "foo",
        #       protocol: "tcp"
        #     }
        #
        # Note that "protocol" is optional and will default to "tcp".
        #
        # @param [Array<Hash>] ports An array of ports to set. See documentation
        # for more information on the format.
        def forward_ports(ports)
          args = []
          ports.each do |options|
            protocol = options[:protocol] || 'tcp'
            pf_builder = [
              options[:name],
              options[:host_port],
              @uuid,
              options[:guest_port]
            ]

            args.concat(["--nat-#{protocol}-add", pf_builder.join(',')])
          end

          execute_prlsrvctl('net', 'set', read_shared_network_id, *args)
        end

        # Lists all snapshots for the specified VM. Returns an empty hash if
        # there are no snapshots.
        #
        # @param [String] uuid Name or UUID of the target VM.
        # @return [<String => String>] {'Snapshot Name' => 'Snapshot UUID'}
        def list_snapshots(uuid)
          settings = read_settings(uuid)
          snap_config = File.join(settings.fetch('Home'), 'Snapshots.xml')

          # There are no snapshots, exit
          return {} unless File.exist?(snap_config)

          xml = Nokogiri::XML(File.read(snap_config))
          snapshots = {}

          # Loop over all 'SavedStateItem' and fetch 'Name' => 'ID' pairs
          xml.xpath('//SavedStateItem').each do |snap|
            snap_id = snap.attr('guid')

            # The first entry is always empty (the base sate)
            next if snap_id.empty?

            snap_name = snap.at('Name').text
            snapshots[snap_name] = snap_id
          end

          snapshots
        end

        # Halts the virtual machine (pulls the plug).
        def halt(force = false)
          args = ['stop', @uuid]
          args << '--kill' if force
          execute_prlctl(*args)
        end

        # Returns a list of bridged interfaces.
        #
        # @return [Array<Symbol => String>]
        def read_bridged_interfaces
          host_hw_info = read_host_info.fetch('Hardware info', {})
          net_list = host_hw_info.select do |name, attrs|
            # Get all network interfaces except 'vnicXXX'
            attrs.fetch('type') == 'net' and name !~ /^(vnic(.+?))$/
          end

          bridged_ifaces = []
          net_list.keys.each do |iface|
            info = {}
            ifconfig = execute('ifconfig', iface)
            # Assign default values
            info[:name] = iface
            info[:ip] = '0.0.0.0'
            info[:netmask] = '0.0.0.0'
            info[:status] = 'Down'

            info[:ip] = $1.to_s if ifconfig =~ /(?<=inet\s)(\S*)/
            if ifconfig =~ /(?<=netmask\s)(\S*)/
              # Netmask will be converted from hex to dec:
              # '0xffffff00' -> '255.255.255.0'
              info[:netmask] = $1.hex.to_s(16).scan(/../).each.map { |octet| octet.hex }.join('.')
            end
            info[:status] = 'Up' if ifconfig =~ /\W(UP)\W/ and ifconfig !~ /(?<=status:\s)inactive$/

            bridged_ifaces << info
          end
          bridged_ifaces
        end

        # Returns the list of port forwarding rules.
        # Each rule will be represented as a hash with the following keys:
        #
        #     {
        #       name:      'example',
        #       protocol:  'tcp',
        #       guest:     'target-vm-uuid',
        #       hostport:  '8080',
        #       guestport: '80'
        #     }
        #
        # @param [Boolean] global If true, returns all the rules on the host.
        # Otherwise only rules related to the context VM will be returned.
        # @return [Array<Symbol => String>]
        def read_forwarded_ports(global = false)
          all_rules = read_shared_interface[:nat]

          if global
            all_rules
          else
            all_rules.select { |r| r[:guest].include?(@uuid) }
          end
        end

        # Returns an IP of the virtual machine fetched from the DHCP lease file.
        # It requires that Shared network adapter is configured for this VM
        # and it obtains an IP via DHCP.
        # Returns an empty string if the IP coudn't be determined this way.
        #
        # @return [String] IP address leased by DHCP server in "Shared" network
        def read_guest_ip_dhcp
          mac_addr = read_mac_address.downcase
          leases_file = '/Library/Preferences/Parallels/parallels_dhcp_leases'
          leases = {}
          begin
            File.open(leases_file).grep(/#{mac_addr}/) do |line|
              _, ip, exp, dur, = line.split /([\d.]*)="(\d*),(\d*),(\w*),(\w*)".*/
              leases[ip] = exp.to_i - dur.to_i
            end
          rescue Errno::EACCES
            raise Errors::DhcpLeasesNotAccessible, leases_file: leases_file.to_s
          rescue Errno::ENOENT
            # File does not exist
            # Perhaps, it is the fist start of Parallels Desktop
            return ''
          end

          return '' if leases.empty?

          # Get the most resent lease and return an associated IP
          leases.max_by { |_ip, lease_time| lease_time }.first
        end

        # Returns an IP of the virtual machine fetched from prlctl.
        # Returns an empty string if the IP coudn't be determined this way.
        #
        # @return [String] IP address returned by `prlctl list -f` command
        def read_guest_ip_prlctl
          vm_info = json { execute_prlctl('list', @uuid, '--full', '--json') }
          ip = vm_info.first.fetch('ip_configured', '')
          ip == '-' ? '' : ip
        end

        # Returns path to the Parallels Tools ISO file.
        #
        # @param [String] guest_os Guest os type: "linux", "darwin" or "windows"
        # @return [String] Path to the ISO.
        def read_guest_tools_iso_path(guest_os, arch=nil)
          guest_os = (guest_os + (['arm', 'arm64', 'aarch64'].include?(arch.to_s.strip) ? '_arm' : '')).to_sym
          iso_name = {
            linux: 'prl-tools-lin.iso',
            linux_arm: 'prl-tools-lin-arm.iso',
            darwin: 'prl-tools-mac.iso',
            darwin_arm: 'prl-tools-mac-arm.iso',
            windows: 'PTIAgent.exe'
          }
          return nil unless iso_name[guest_os]

          bundle_id = 'com.parallels.desktop.console'
          bundle_path = execute('mdfind', "kMDItemCFBundleIdentifier == #{bundle_id}")
          iso_path = File.expand_path("./Contents/Resources/Tools/#{iso_name[guest_os]}",
                                      bundle_path.split("\n")[0])

          raise Errors::ParallelsToolsIsoNotFound, iso_path: iso_path unless File.exist?(iso_path)

          iso_path
        end

        # Returns the state of guest tools that is installed on this VM.
        # Can be any of:
        # * :installed
        # * :not_installed
        # * :possibly_installed
        # * :outdated
        #
        # @return [Symbol]
        def read_guest_tools_state
          state = read_settings.fetch('GuestTools', {}).fetch('state', nil)
          state ||= 'not_installed'
          state.to_sym
        end

        # Returns Parallels Desktop properties and common information about
        # the host machine.
        #
        # @return [<Symbol => String>]
        def read_host_info
          json { execute_prlctl('server', 'info', '--json') }
        end

        # Returns a list of available host only interfaces.
        # Each interface is represented as a Hash with the following details:
        #
        # {
        #   name:     'Host-Only',     # Parallels Network ID
        #   ip:       '10.37.129.2',   # IP address of the interface
        #   netmask:  '255.255.255.0', # netmask associated with the interface
        #   status:   'Up'             # status of the interface
        # }
        #
        # @return [Array<Symbol => String>]
        def read_host_only_interfaces
          net_list = read_virtual_networks
          net_list.keep_if { |net| net['Type'] == 'host-only' }

          hostonly_ifaces = []
          net_list.each do |iface|
            net_info = json do
              execute_prlsrvctl('net', 'info', iface['Network ID'], '--json')
            end

            iface = {
              name: net_info['Network ID'],
              status: 'Down'
            }

            adapter = net_info['Parallels adapter']
            if adapter
              iface[:ip] = adapter['IPv4 address']
              iface[:netmask] = adapter['IPv4 subnet mask']
              iface[:status] = 'Up'

              if adapter['IPv6 address'] && adapter['IPv6 subnet mask']
                iface[:ipv6] = adapter['IPv6 address']
                iface[:ipv6_prefix] = adapter['IPv6 subnet mask']
              end
            end

            hostonly_ifaces << iface
          end
          hostonly_ifaces
        end

        # Returns the MAC address of the first Shared network interface.
        #
        # @return [String]
        def read_mac_address
          hw_info = read_settings.fetch('Hardware', {})
          shared_ifaces = hw_info.select do |name, params|
            name.start_with?('net') && params['type'] == 'shared'
          end

          raise Errors::SharedInterfaceNotFound if shared_ifaces.empty?

          shared_ifaces.values.first.fetch('mac', nil)
        end

        # Returns the array of network interface card MAC addresses
        #
        # @return [Array<String>]
        def read_mac_addresses
          read_vm_option('mac').strip.gsub(':', '').split(' ')
        end

        # Returns a list of network interfaces of the VM.
        #
        # @return [<Integer => Hash>]
        def read_network_interfaces
          nics = {}

          # Get enabled VM's network interfaces
          ifaces = read_settings.fetch('Hardware', {}).keep_if do |dev, params|
            dev.start_with?('net') and params.fetch('enabled', true)
          end
          ifaces.each do |name, params|
            adapter = name.match(/^net(\d+)$/)[1].to_i
            nics[adapter] ||= {}

            case params['type']
            when 'shared'
              nics[adapter][:type] = :shared
            when 'host'
              nics[adapter][:type] = :hostonly
              nics[adapter][:hostonly] = params.fetch('iface', '')
            when 'bridged'
              nics[adapter][:type] = :bridged
              nics[adapter][:bridge] = params.fetch('iface', '')
            end
          end
          nics
        end

        # Returns virtual machine settings
        #
        # @return [<String => String, Hash>]
        def read_settings(uuid = @uuid)
          vm = json { execute_prlctl('list', uuid, '--info', '--no-header', '--json') }
          vm.last
        end

        # Returns the unique name (e.q. "ID") on the first Shared network in
        # Parallels Desktop configuration.
        # By default there is only one called "Shared".
        #
        # @return [String] Shared network ID
        def read_shared_network_id
          'Shared'
        end

        # Returns info about shared network interface.
        #
        # @return [<Symbol => String, Hash>]
        def read_shared_interface
          net_info = json do
            execute_prlsrvctl('net', 'info', read_shared_network_id, '--json')
          end

          iface = {
            nat: [],
            status: 'Down'
          }
          adapter = net_info['Parallels adapter']

          if adapter
            iface[:ip] = adapter['IPv4 address']
            iface[:netmask] = adapter['IPv4 subnet mask']
            iface[:status] = 'Up'
          end

          if net_info.key?('DHCPv4 server')
            iface[:dhcp] = {
              ip: net_info['DHCPv4 server']['Server address'],
              lower: net_info['DHCPv4 server']['IP scope start address'],
              upper: net_info['DHCPv4 server']['IP scope end address']
            }
          end

          net_info['NAT server'].each do |group, rules|
            rules.each do |name, params|
              iface[:nat] << {
                name: name,
                protocol: group == 'TCP rules' ? 'tcp' : 'udp',
                guest: params['destination IP/VM id'],
                hostport: params['source port'],
                guestport: params['destination port']
              }
            end
          end

          iface
        end

        # Returns a list of shared folders in format:
        # { id => hostpath, ... }
        #
        # @return [<String => String>]
        def read_shared_folders
          shf_info = read_settings.fetch('Host Shared Folders', {})
          list = {}
          shf_info.delete_if { |k, _v| k == 'enabled' }.each do |id, data|
            list[id] = data.fetch('path')
          end

          list
        end

        # Returns the current state of this VM.
        #
        # @return [Symbol] Virtual machine state
        def read_state
          read_vm_option('status').strip.to_sym
        end

        # Returns a list of all forwarded ports in use by active
        # virtual machines.
        #
        # @return [Array]
        def read_used_ports
          # Ignore our own used ports
          read_forwarded_ports(true).reject { |r| r[:guest].include?(@uuid) }
        end

        # Returns the configuration of all virtual networks in Parallels Desktop.
        #
        # @return [Array<String => String>]
        def read_virtual_networks
          json { execute_prlsrvctl('net', 'list', '--json') }
        end

        # Returns a value of specified VM option. Raises an exception if value
        # is not available
        #
        # @param [String] option Name of option (See all: `prlctl list -L`)
        # @param [String] uuid Virtual machine UUID
        # @return [String]
        def read_vm_option(option, uuid = @uuid)
          out = execute_prlctl('list', uuid, '--no-header', '-o', option).strip
          raise Errors::ParallelsVMOptionNotFound, vm_option: option if out.empty?

          out
        end

        # Returns names and ids of all virtual machines and templates.
        #
        # @return [<String => String>]
        def read_vms
          args = %w[list --all --no-header --json -o name,uuid]
          vms_arr = json { execute_prlctl(*args) }
          templates_arr = json { execute_prlctl(*args, '--template') }

          vms = vms_arr | templates_arr
          Hash[vms.map { |i| [i.fetch('name'), i.fetch('uuid')] }]
        end

        # Returns the configuration of all VMs and templates.
        #
        # @return [Array <String => String>]
        def read_vms_info
          args = %w[list --all --info --no-header --json]
          vms_arr = json { execute_prlctl(*args) }
          templates_arr = json { execute_prlctl(*args, '--template') }

          vms_arr | templates_arr
        end

        # Registers the virtual machine
        #
        # @param [String] pvm_file Path to the machine image (*.pvm)
        # @param [Array<String>] opts List of options for "prlctl register"
        def register(pvm_file, opts = [])
          execute_prlctl('register', pvm_file, *opts)
        end

        # Switches the VM state to the specified snapshot
        #
        # @param [String] uuid Name or UUID of the target VM
        # @param [String] snapshot_id Snapshot ID
        def restore_snapshot(uuid, snapshot_id)
          # Sometimes this command fails with 'Data synchronization is currently
          # in progress'. Just wait and retry.
          retryable(on: VagrantPlugins::Parallels::Errors::ExecutionError, tries: 2, sleep: 2) do
            execute_prlctl('snapshot-switch', uuid, '-i', snapshot_id)
          end
        end

        # Resumes the virtual machine.
        #
        def resume
          execute_prlctl('resume', @uuid)
        end

        # Sets the name of the virtual machine.
        #
        # @param [String] uuid VM name or UUID
        # @param [String] new_name New VM name
        def set_name(uuid, new_name)
          execute_prlctl('set', uuid, '--name', new_name)
        end

        # Sets Power Consumption method.
        #
        # @param [Boolean] optimized Use "Longer Battery Life"
        # instead "Better Performance"
        def set_power_consumption_mode(optimized)
          state = optimized ? 'on' : 'off'
          execute_prlctl('set', @uuid, '--longer-battery-life', state)
        end

        # Share a set of folders on this VM.
        #
        # @param [Array<Symbol => String>] folders
        def share_folders(folders)
          folders.each do |folder|
            # Add the shared folder
            execute_prlctl('set', @uuid,
                           '--shf-host-add', folder[:name],
                           '--path', folder[:hostpath])
          end
        end

        # Reads the SSH IP of this VM from DHCP lease file or from `prlctl list`
        # command - whatever returns a non-empty result first.
        # The method with DHCP does not work for *.macvm VMs on Apple M-series Macs,
        # so we try both sources here.
        #
        # @return [String] IP address to use for SSH connection to the VM.
        def ssh_ip
          5.times do
            ip = read_guest_ip_dhcp
            return ip unless ip.empty?

            ip = read_guest_ip_prlctl
            return ip unless ip.empty?

            sleep 2
          end

          # We didn't manage to determine IP - return nil and
          # expect SSH client to do a retry
          return nil
        end

        # Reads the SSH port of this VM.
        #
        # @param [Integer] expected Expected guest port of SSH.
        # @return [Integer] Port number to use for SSH connection to the VM.
        def ssh_port(expected)
          expected
        end

        # Starts the virtual machine.
        #
        def start
          execute_prlctl('start', @uuid)
        end

        # Suspends the virtual machine.
        def suspend
          execute_prlctl('suspend', @uuid)
        end

        # Performs un-registeration of the specified VM in Parallels Desktop.
        # Virtual machine will be removed from the VM list, but its image will
        # not be deleted from the disk. So, it can be registered again.
        def unregister(uuid)
          execute_prlctl('unregister', uuid)
        end

        # Unshare folders.
        def unshare_folders(names)
          names.each do |name|
            execute_prlctl('set', @uuid, '--shf-host-del', name)
          end
        end

        # Checks if a VM with the given UUID exists.
        #
        # @return [Boolean]
        def vm_exists?(uuid)
          5.times do
            result = raw(@prlctl_path, 'list', uuid)
            return true if result.exit_code == 0

            # Sometimes this happens. In this case, retry.
            # If we don't see this text, the VM really doesn't exist.
            return false unless result.stderr.include?('Login failed:')

            # Sleep a bit though to give Parallels Desktop time to fix itself
            sleep 2
          end

          # If we reach this point, it means that we consistently got the
          # failure, do a standard prlctl now. This will raise an
          # exception if it fails again.
          execute_prlctl('list', uuid)
          true
        end

        # Wraps 'execute' and returns the output of given 'prlctl' subcommand.
        def execute_prlctl(*command, &block)
          execute(@prlctl_path, *command, &block)
        end

        private

        # Wraps 'execute' and returns the output of given 'prlsrvctl' subcommand.
        def execute_prlsrvctl(*command, &block)
          execute(@prlsrvctl_path, *command, &block)
        end

        # Execute the given command and return the output.
        def execute(*command, &block)
          r = raw(*command, &block)

          # If the command was a failure, then raise an exception that is
          # nicely handled by Vagrant.
          if r.exit_code != 0
            if @interrupted
              @logger.info('Exit code != 0, but interrupted. Ignoring.')
            else
              # If there was an error running command, show the error and the
              # output.
              raise VagrantPlugins::Parallels::Errors::ExecutionError,
                    command: command.inspect,
                    stderr: r.stderr
            end
          end
          r.stdout
        end

        # Parses given block (JSON string) to object
        def json
          data = yield
          raise_error = false

          begin
            JSON.parse(data)
          rescue JSON::JSONError
            # We retried already, raise the issue and be done
            raise VagrantPlugins::Parallels::Errors::JSONParseError, data: data if raise_error

            # Remove garbage before/after json string[GH-204]
            data = data[/({.*}|\[.*\])/m]

            # Remove all control characters unsupported by JSON [GH-219]
            data.tr!("\u0000-\u001f", '')

            raise_error = true
            retry
          end
        end

        # Executes a command and returns the raw result object.
        def raw(*command, &block)
          int_callback = lambda do
            @interrupted = true

            # We have to execute this in a thread due to trap contexts
            # and locks.
            Thread.new { @logger.info('Interrupted.') }
          end

          # Append in the options for subprocess
          command << { notify: [:stdout, :stderr] }

          Vagrant::Util::Busy.busy(int_callback) do
            Vagrant::Util::Subprocess.execute(*command, &block)
          end
        end

        def util_path(bin)
          path = Vagrant::Util::Which.which(bin)
          return path if path

          ['/usr/local/bin', '/usr/bin'].each do |folder|
            path = File.join(folder, bin)
            return path if File.file?(path)
          end
          nil
        end

      end
    end
  end
end
