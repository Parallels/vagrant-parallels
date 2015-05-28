require 'log4r'
require 'nokogiri'
require 'securerandom'

require 'vagrant/util/platform'

require File.expand_path("../base", __FILE__)

module VagrantPlugins
  module Parallels
    module Driver
      # Driver for Parallels Desktop 8.
      class PD_8 < Base
        def initialize(uuid)
          super()

          @logger = Log4r::Logger.new('vagrant_parallels::driver::pd_8')
          @uuid = uuid
        end


        def compact(uuid)
          used_drives = read_settings.fetch('Hardware', {}).select do |name, _|
            name.start_with? 'hdd'
          end
          used_drives.each_value do |drive_params|
            execute(@prldisktool_path, 'compact', '--hdd', drive_params['image']) do |type, data|
              lines = data.split("\r")
              # The progress of the compact will be in the last line. Do a greedy
              # regular expression to find what we're looking for.
              if lines.last =~ /.+?(\d{,3}) ?%/
                yield $1.to_i if block_given?
              end
            end
          end
        end

        def clear_shared_folders
          share_ids = read_shared_folders.keys
          share_ids.each do |id|
            execute_prlctl('set', @uuid, '--shf-host-del', id)
          end
        end

        def create_host_only_network(options)
          # Create the interface
          execute_prlsrvctl('net', 'add', options[:network_id], '--type', 'host-only')

          # Configure it
          args = ["--ip", "#{options[:adapter_ip]}/#{options[:netmask]}"]
          if options[:dhcp]
            args.concat(["--dhcp-ip", options[:dhcp][:ip],
                         "--ip-scope-start", options[:dhcp][:lower],
                         "--ip-scope-end", options[:dhcp][:upper]])
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

        def delete
          execute_prlctl('delete', @uuid)
        end

        def delete_disabled_adapters
          read_settings.fetch('Hardware', {}).each do |adapter, params|
            if adapter.start_with?('net') and !params.fetch('enabled', true)
              execute_prlctl('set', @uuid, '--device-del', adapter)
            end
          end
        end

        def delete_unused_host_only_networks
          networks = read_virtual_networks

          # 'Shared'(vnic0) and 'Host-Only'(vnic1) are default in Parallels Desktop
          # They should not be deleted anyway.
          networks.keep_if do |net|
            net['Type'] == "host-only" &&
              net['Bound To'].match(/^(?>vnic|Parallels Host-Only #)(\d+)$/)[1].to_i >= 2
          end

          read_vms_info.each do |vm|
            used_nets = vm.fetch('Hardware', {}).select { |name, _| name.start_with? 'net' }
            used_nets.each_value do |net_params|
              networks.delete_if { |net|  net['Bound To'] == net_params.fetch('iface', nil) }
            end

          end

          networks.each do |net|
            # Delete the actual host only network interface.
            execute_prlsrvctl('net', 'del', net['Network ID'])
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
              args.concat(["--device-set","net#{adapter[:adapter]}", "--enable"])
            else
              args.concat(["--device-add", "net"])
            end

            if adapter[:type] == :hostonly
              # Determine interface to which it has been bound
              net_info = json do
                execute_prlsrvctl('net', 'info', adapter[:hostonly], '--json')
              end

              # Oddly enough, but there is a 'bridge' type anyway.
              # The only difference is the destination interface:
              # - in host-only (private) network it will be bridged to the 'vnicX' device
              # - in real bridge (public) network it will be bridged to the assigned device
              args.concat(["--type", "bridged", "--iface", net_info['Bound To']])
            elsif adapter[:type] == :bridged
              args.concat(["--type", "bridged", "--iface", adapter[:bridge]])
            elsif adapter[:type] == :shared
              args.concat(["--type", "shared"])
            end

            if adapter[:mac_address]
              args.concat(["--mac", adapter[:mac_address]])
            end

            if adapter[:nic_type]
              args.concat(["--adapter-type", adapter[:nic_type].to_s])
            end

            execute_prlctl("set", @uuid, *args)
          end
        end

        def export(path, tpl_name)
          execute_prlctl('clone', @uuid,
                         '--name', tpl_name,
                         '--template',
                         '--dst', path.to_s) do |type, data|
            lines = data.split("\r")
            # The progress of the export will be in the last line. Do a greedy
            # regular expression to find what we're looking for.
            if lines.last =~ /.+?(\d{,3}) ?%/
              yield $1.to_i if block_given?
            end
          end
          read_vms[tpl_name]
        end

        def halt(force=false)
          args = ['stop', @uuid]
          args << '--kill' if force
          execute_prlctl(*args)
        end

        def import(tpl_name)
          vm_name = "#{tpl_name}_#{(Time.now.to_f * 1000.0).to_i}_#{rand(100000)}"

          execute_prlctl('clone', tpl_name, '--name', vm_name) do |type, data|
            lines = data.split("\r")
            # The progress of the import will be in the last line. Do a greedy
            # regular expression to find what we're looking for.
            if lines.last =~ /.+?(\d{,3}) ?%/
              yield $1.to_i if block_given?
            end
          end
          read_vms[vm_name]
        end

        def read_bridged_interfaces
          host_hw_info = read_host_info.fetch("Hardware info")
          net_list = host_hw_info.select do |name, attrs|
            # Get all network interfaces except 'vnicXXX'
            attrs.fetch("type") == "net" and name !~ /^(vnic(.+?))$/
          end

          bridged_ifaces = []
          net_list.keys.each do |iface|
            info = {}
            ifconfig = execute('ifconfig', iface)
            # Assign default values
            info[:name]    = iface
            info[:ip]      = "0.0.0.0"
            info[:netmask] = "0.0.0.0"
            info[:status]  = "Down"

            if ifconfig =~ /(?<=inet\s)(\S*)/
              info[:ip] = $1.to_s
            end
            if ifconfig =~ /(?<=netmask\s)(\S*)/
              # Netmask will be converted from hex to dec:
              # '0xffffff00' -> '255.255.255.0'
              info[:netmask] = $1.hex.to_s(16).scan(/../).each.map{|octet| octet.hex}.join(".")
            end
            if ifconfig =~ /\W(UP)\W/ and ifconfig !~ /(?<=status:\s)inactive$/
              info[:status] = "Up"
            end

            bridged_ifaces << info
          end
          bridged_ifaces
        end

        def read_guest_ip
          mac_addr = read_mac_address.downcase
          leases_file = "/Library/Preferences/Parallels/parallels_dhcp_leases"
          begin
            File.open(leases_file).grep(/#{mac_addr}/) do |line|
              return line[/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/]
            end
          rescue Errno::EACCES
            raise Errors::DhcpLeasesNotAccessible, :leases_file => leases_file.to_s
          rescue Errno::ENOENT
            # File does not exist
            # Perhaps, it is the fist start of Parallels Desktop
            return nil
          end

          nil
        end

        def read_guest_tools_iso_path(guest_os)
          guest_os = guest_os.to_sym
          iso_name ={
            linux:   "prl-tools-lin.iso",
            darwin:  "prl-tools-mac.iso",
            windows: "prl-tools-win.iso"
          }
          return nil if !iso_name[guest_os]

          bundle_id =  'com.parallels.desktop.console'
          bundle_path = execute('mdfind', "kMDItemCFBundleIdentifier == #{bundle_id}")
          iso_path = File.expand_path("./Contents/Resources/Tools/#{iso_name[guest_os]}",
                                      bundle_path.split("\n")[0])

          if !File.exist?(iso_path)
            raise Errors::ParallelsToolsIsoNotFound, :iso_path => iso_path
          end

          iso_path
        end

        def read_guest_tools_state
          state = read_settings.fetch('GuestTools', {}).fetch('state', nil)
          state = "not_installed" if !state
          state.to_sym
        end

        def read_host_info
          json { execute_prlctl('server', 'info', '--json') }
        end

        def read_host_only_interfaces
          net_list = read_virtual_networks
          net_list.keep_if { |net| net['Type'] == "host-only" }

          hostonly_ifaces = []
          net_list.each do |iface|
            info = {}
            net_info = json { execute_prlsrvctl('net', 'info', iface['Network ID'], '--json') }
            info[:name]     = net_info['Network ID']
            info[:bound_to] = net_info['Bound To']
            info[:ip]       = net_info['Parallels adapter']['IP address']
            info[:netmask]  = net_info['Parallels adapter']['Subnet mask']
            # Such interfaces are always in 'Up'
            info[:status]   = "Up"

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

        def read_mac_address
          # Get MAC of Shared network interface (net0)
          read_vm_option('mac').strip.split(' ').first.gsub(':', '')
        end

        def read_mac_addresses
          macs = read_vm_option('mac').strip.split(' ')
          Hash[macs.map.with_index{ |mac, ind| [ind, mac.gsub(':', '')] }]
        end

        def read_network_interfaces
          nics = {}

          # Get enabled VM's network interfaces
          ifaces = read_settings.fetch('Hardware', {}).keep_if do |dev, params|
            dev.start_with?('net') and params.fetch("enabled", true)
          end
          ifaces.each do |name, params|
            adapter = name.match(/^net(\d+)$/)[1].to_i
            nics[adapter] ||= {}

            if params['type'] == "shared"
              nics[adapter][:type] = :shared
            elsif params['type'] == "host"
              # It is PD internal host-only network and it is bounded to 'vnic1'
              nics[adapter][:type] = :hostonly
              nics[adapter][:hostonly] = "vnic1"
            elsif params['type'] == "bridged" and params.fetch('iface','').start_with?('vnic')
              # Bridged to the 'vnicXX'? Then it is a host-only, actually.
              nics[adapter][:type] = :hostonly
              nics[adapter][:hostonly] = params.fetch('iface','')
            elsif params['type'] == "bridged"
              nics[adapter][:type] = :bridged
              nics[adapter][:bridge] = params.fetch('iface','')
            end
          end
          nics
        end

        def read_settings
          vm = json { execute_prlctl('list', @uuid, '--info', '--no-header', '--json')  }
          vm.last
        end

        def read_shared_network_id
          # There should be only one Shared interface
          shared_net = read_virtual_networks.detect do |net|
            net['Type'] == 'shared'
          end
          shared_net.fetch('Network ID')
        end

        def read_shared_interface
          net_info = json do
            execute_prlsrvctl('net', 'info', read_shared_network_id, '--json')
          end
          info = {
            name:    net_info['Bound To'],
            ip:      net_info['Parallels adapter']['IP address'],
            netmask: net_info['Parallels adapter']['Subnet mask'],
            status:  "Up"
          }

          if net_info.key?('DHCPv4 server')
            info[:dhcp] = {
              ip:    net_info['DHCPv4 server']['Server address'],
              lower: net_info['DHCPv4 server']['IP scope start address'],
              upper: net_info['DHCPv4 server']['IP scope end address']
            }
          end

          info
        end

        def read_shared_folders
          shf_info = read_settings.fetch("Host Shared Folders", {})
          list = {}
          shf_info.delete_if {|k,v| k == "enabled"}.each do |id, data|
            list[id] = data.fetch("path")
          end

          list
        end

        def read_state
          read_vm_option('status').strip.to_sym
        end

        def read_virtual_networks
          json { execute_prlsrvctl('net', 'list', '--json') }
        end

        def read_vm_option(option, uuid=@uuid)
          out = execute_prlctl('list', uuid,'--no-header', '-o', option).strip
          if out.empty?
            raise Errors::ParallelsVMOptionNotFound, vm_option: option
          end

          out
        end

        def read_vms
          args = %w(list --all --no-header --json -o name,uuid)
          vms_arr = json([]) { execute_prlctl(*args) }
          templates_arr = json([]) { execute_prlctl(*args, '--template') }

          vms = vms_arr | templates_arr
          Hash[vms.map { |i| [i.fetch('name'), i.fetch('uuid')] }]
        end

        # Parse the JSON from *all* VMs and templates.
        # Then return an array of objects (without duplicates)
        def read_vms_info
          args = %w(list --all --info --no-header --json)
          vms_arr = json([]) { execute_prlctl(*args) }
          templates_arr = json([]) { execute_prlctl(*args, '--template') }

          vms_arr | templates_arr
        end

        def read_vms_paths
          list = {}
          read_vms_info.each do |item|
            if Dir.exists? item.fetch('Home')
              list[File.realpath item.fetch('Home')] = item.fetch('ID')
            end
          end

          list
        end

        def regenerate_src_uuid
          settings = read_settings
          vm_config = File.join(settings.fetch('Home'), 'config.pvs')

          # Generate and put new SourceVmUuid
          xml = Nokogiri::XML(File.open(vm_config))
          p = '//ParallelsVirtualMachine/Identification/SourceVmUuid'
          xml.xpath(p).first.content = "{#{SecureRandom.uuid}}"

          File.open(vm_config, 'w') do |f|
            f.write xml.to_xml
          end
        end

        def register(pvm_file)
          args = [@prlctl_path, 'register', pvm_file]

          3.times do
            result = raw(*args)
            # Exit if everything is OK
            return if result.exit_code == 0

            # It may occur in the race condition with other Vagrant processes.
            # It is OK, just exit.
            return if result.stderr.include?('is already registered.')

            # Sleep a bit though to give Parallels Desktop time to fix itself
            sleep 2
          end

          # If we reach this point, it means that we consistently got the
          # failure, do a standard execute now. This will raise an
          # exception if it fails again.
          execute_prlctl(*args)
        end

        def registered?(uuid)
          args = %w(list --all --info --no-header -o uuid)

          execute_prlctl(*args).include?(uuid) ||
            execute_prlctl(*args, '--template').include?(uuid)
        end

        def resume
          execute_prlctl('resume', @uuid)
        end

        def set_mac_address(mac)
          execute_prlctl('set', @uuid,
                         '--device-set', 'net0',
                         '--type', 'shared',
                         '--mac', mac)
        end

        def set_name(name)
          execute_prlctl('set', @uuid, '--name', name)
        end

        def share_folders(folders)
          folders.each do |folder|
            # Add the shared folder
            execute_prlctl('set', @uuid,
                           '--shf-host-add', folder[:name],
                           '--path', folder[:hostpath])
          end
        end

        def ssh_ip
          read_guest_ip
        end

        def ssh_port(expected_port)
          expected_port
        end

        def start
          execute_prlctl('start', @uuid)
        end

        def suspend
          execute_prlctl('suspend', @uuid)
        end

        def unregister(uuid)
          args = [@prlctl_path, 'unregister', uuid]
          3.times do
            result = raw(*args)
            # Exit if everything is OK
            return if result.exit_code == 0

            # It may occur in the race condition with other Vagrant processes.
            # Both are OK, just exit.
            return if result.stderr.include?('is not registered')
            return if result.stderr.include?('is being cloned')

            # Sleep a bit though to give Parallels Desktop time to fix itself
            sleep 2
          end

          # If we reach this point, it means that we consistently got the
          # failure, do a standard execute now. This will raise an
          # exception if it fails again.
          execute_prlctl(*args)
        end

        def unshare_folders(names)
          names.each do |name|
            execute_prlctl('set', @uuid, '--shf-host-del', name)
          end
        end

        def vm_exists?(uuid)
          5.times do |i|
            result = raw(@prlctl_path, 'list', uuid)
            return true if result.exit_code == 0

            # Sometimes this happens. In this case, retry. If
            # we don't see this text, the VM really probably doesn't exist.
            return false if !result.stderr.include?('Login failed:')

            # Sleep a bit though to give Parallels Desktop time to fix itself
            sleep 2
          end

          # If we reach this point, it means that we consistently got the
          # failure, do a standard prlctl now. This will raise an
          # exception if it fails again.
          execute_prlctl('list', uuid)
          true
        end
      end
    end
  end
end
