require 'log4r'
require 'json'

require 'vagrant/util/busy'
require "vagrant/util/network_ip"
require 'vagrant/util/platform'
require 'vagrant/util/retryable'
require 'vagrant/util/subprocess'

module VagrantPlugins
  module Parallels
    module Driver
      # Base class for all Parallels drivers.
      #
      # This class provides useful tools for things such as executing
      # PrlCtl and handling SIGINTs and so on.
      class PrlCtl
        # Include this so we can use `Subprocess` more easily.
        include Vagrant::Util::Retryable
        include Vagrant::Util::NetworkIP

        attr_reader :uuid

        def initialize(uuid)
          @logger = Log4r::Logger.new("vagrant::provider::parallels::prlctl")

          # This flag is used to keep track of interrupted state (SIGINT)
          @interrupted = false

          # Store machine id
          @uuid = uuid

          # Set the path to prlctl
          @prlctl_path = "prlctl"
          @prlsrvctl_path = "prlsrvctl"

          @logger.info("CLI prlctl path: #{@prlctl_path}")
          @logger.info("CLI prlsrvctl path: #{@prlsrvctl_path}")
        end

        def compact(uuid=nil)
          uuid ||= @uuid
          # TODO: VM can have more than one hdd!
          path_to_hdd = read_settings(uuid).fetch("Hardware", {}).fetch("hdd0", {}).fetch("image", nil)
          raw('prl_disk_tool', 'compact', '--hdd', path_to_hdd) do |type, data|
            lines = data.split("\r")
            # The progress of the import will be in the last line. Do a greedy
            # regular expression to find what we're looking for.
            if lines.last =~ /.+?(\d{,3}) ?%/
              yield $1.to_i if block_given?
            end
          end
        end

        def create_host_only_network(options)
          # Create the interface
          execute(:prlsrvctl, "net", "add", options[:name], "--type", "host-only")

          # Configure it
          args = ["--ip", "#{options[:adapter_ip]}/#{options[:netmask]}"]
          if options[:dhcp]
            args.concat(["--dhcp-ip", options[:dhcp][:ip],
                         "--ip-scope-start", options[:dhcp][:lower],
                         "--ip-scope-end", options[:dhcp][:upper]])
          end

          execute(:prlsrvctl, "net", "set", options[:name], *args)

          # Determine interface to which it has been bound
          net_info = json { execute(:prlsrvctl, 'net', 'info', options[:name], '--json', retryable: true) }
          bound_to = net_info['Bound To']

          # Return the details
          return {
              :name => options[:name],
              :bound_to => bound_to,
              :ip   => options[:adapter_ip],
              :netmask => options[:netmask],
              :dhcp => options[:dhcp]
          }
        end

        def clear_shared_folders
          shf = read_settings.fetch("Host Shared Folders", {}).keys
          shf.delete("enabled")
          shf.each do |folder|
            execute("set", @uuid, "--shf-host-del", folder)
          end
        end

        def delete
          execute('delete', @uuid)
        end

        def delete_adapters
          read_settings.fetch('Hardware', {}).each do |adapter, params|
            if adapter.start_with?('net') and !params.fetch("enabled", true)
              execute('set', @uuid, '--device-del', adapter)
            end
          end
        end

        def delete_unused_host_only_networks
          networks = read_virtual_networks()

          # 'Shared'(vnic0) and 'Host-Only'(vnic1) are default in Parallels Desktop
          # They should not be deleted anyway.
          networks.keep_if do |net|
            net['Type'] == "host-only" &&
                net['Bound To'].match(/^(?>vnic|Parallels Host-Only #)(\d+)$/)[1].to_i >= 2
          end

          read_all_info.each do |vm|
            used_nets = vm.fetch('Hardware', {}).select { |name, _| name.start_with? 'net' }
            used_nets.each_value do |net_params|
              networks.delete_if { |net|  net['Bound To'] == net_params.fetch('iface', nil)}
            end

          end

          networks.each do |net|
            # Delete the actual host only network interface.
            execute(:prlsrvctl, "net", "del", net["Network ID"])
          end
        end

        def enable_adapters(adapters)
          # Get adapters which have already configured for this VM
          # Such adapters will be just overridden
          existing_adapters = read_settings.fetch('Hardware', {}).keys.select { |name| name.start_with? 'net' }

          # Disable all previously existing adapters (except shared 'vnet0')
          existing_adapters.each do |adapter|
            if adapter != 'vnet0'
              execute('set', @uuid, '--device-set', adapter, '--disable')
            end
          end

          adapters.each do |adapter|
            args = []
            if existing_adapters.include? "net#{adapter[:adapter]}"
              args.concat(["--device-set","net#{adapter[:adapter]}", "--enable"])
            else
              args.concat(["--device-add", "net"])
            end

            if adapter[:hostonly] or adapter[:bridge]
              # Oddly enough, but there is a 'bridge' anyway.
              # The only difference is the destination interface:
              # - in host-only (private) network it will be bridged to the 'vnicX' device
              # - in real bridge (public) network it will be bridged to the assigned device
              args.concat(["--type", "bridged", "--iface", adapter[:bound_to]])
            end

            if adapter[:shared]
              args.concat(["--type", "shared"])
            end

            if adapter[:dhcp]
              args.concat(["--dhcp", "yes"])
            elsif adapter[:ip]
              args.concat(["--ipdel", "all", "--ipadd", "#{adapter[:ip]}/#{adapter[:netmask]}"])
            else
              args.concat(["--dhcp", "no"])
            end

            if adapter[:mac_address]
              args.concat(["--mac", adapter[:mac_address]])
            end

            if adapter[:nic_type]
              args.concat(["--adapter-type", adapter[:nic_type].to_s])
            end

            execute("set", @uuid, *args)
          end
        end

        def export(path, vm_name)
          execute("clone", @uuid, "--name", vm_name, "--template", "--dst", path.to_s) do |type, data|
            lines = data.split("\r")
            # The progress of the import will be in the last line. Do a greedy
            # regular expression to find what we're looking for.
            if lines.last =~ /.+?(\d{,3}) ?%/
              yield $1.to_i if block_given?
            end
          end

          read_settings(vm_name).fetch('ID', vm_name)
        end

        def halt(force=false)
          args = ['stop', @uuid]
          args << '--kill' if force
          execute(*args)
        end

        def import(template_uuid, vm_name)
          execute("clone", template_uuid, '--name', vm_name) do |type, data|
            lines = data.split("\r")
            # The progress of the import will be in the last line. Do a greedy
            # regular expression to find what we're looking for.
            if lines.last =~ /.+?(\d{,3}) ?%/
              yield $1.to_i if block_given?
            end
          end
          @uuid = read_settings(vm_name).fetch('ID', vm_name)
        end

        def ip
          mac_addr = read_mac_address.downcase
          File.foreach("/Library/Preferences/Parallels/parallels_dhcp_leases") do |line|
            if line.include? mac_addr
              ip = line[/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/]
              return ip
            end
          end
        end

        # Returns a hash of all UUIDs assigned to VMs and templates currently
        # known by Parallels. Keys are 'name' values
        #
        # @return [Hash]
        def read_all_names
          list = {}
          read_all_info.each do |item|
            list[item.fetch('Name')] = item.fetch('ID')
          end

          list
        end

        # Returns a hash of all UUIDs assigned to VMs and templates currently
        # known by Parallels. Keys are 'Home' directories
        #
        # @return [Hash]
        def read_all_paths
          list = {}
          read_all_info.each do |item|
            if Dir.exists? item.fetch('Home')
              list[File.realpath item.fetch('Home')] = item.fetch('ID')
            end
          end

          list
        end

        def read_bridged_interfaces
          net_list = read_virtual_networks()

          # Skip 'vnicXXX' and 'Default' interfaces
          net_list.delete_if do |net|
            net['Type'] != "bridged" or net['Bound To'] =~ /^(vnic(.+?)|Default)$/
          end

          bridged_ifaces = []
          net_list.collect do |iface|
            info = {}
            ifconfig = raw('ifconfig', iface['Bound To']).stdout
            # Assign default values
            info[:name]    = iface['Network ID'].gsub(/\s\(.*?\)$/, '')
            info[:bound_to] = iface['Bound To']
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

        def read_guest_tools_version
          read_settings.fetch('GuestTools', {}).fetch('version', nil)
        end

        def read_host_only_interfaces
          net_list = read_virtual_networks()
          net_list.keep_if { |net| net['Type'] == "host-only" }

          hostonly_ifaces = []
          net_list.collect do |iface|
            info = {}
            net_info = json { execute(:prlsrvctl, 'net', 'info', iface['Network ID'], '--json') }
            # Really we need to work with bounded virtual interface
            info[:name]     = net_info['Network ID']
            info[:bound_to] = net_info['Bound To']
            info[:ip]       = net_info['Parallels adapter']['IP address']
            info[:netmask]  = net_info['Parallels adapter']['Subnet mask']
            # Such interfaces are always in 'Up'
            info[:status]   = "Up"

            # There may be a fake DHCPv4 parameters
            # We can trust them only if adapter IP and DHCP IP are in the same subnet
            dhcp_ip = net_info['DHCPv4 server']['Server address']
            if network_address(info[:ip], info[:netmask]) == network_address(dhcp_ip, info[:netmask])
              info[:dhcp] = {
                :ip      => dhcp_ip,
                :lower   => net_info['DHCPv4 server']['IP scope start address'],
                :upper   => net_info['DHCPv4 server']['IP scope end address']
              }
            end
            hostonly_ifaces << info
          end
        hostonly_ifaces
        end

        def read_mac_address
          read_settings.fetch('Hardware', {}).fetch('net0', {}).fetch('mac', nil)
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

        # Returns the current state of this VM.
        #
        # @return [Symbol]
        def read_state
          read_settings(@uuid).fetch('State', 'inaccessible').to_sym
        end

        def read_virtual_networks
          json { execute(:prlsrvctl, 'net', 'list', '--json', retryable: true) }
        end

        def ready?
          !!guest_execute('uname') rescue false
        end

        def register(pvm_file)
          execute("register", pvm_file)
        end

        def registered?(path)
          # TODO: Make this take UUID and have callers pass that instead
          # Need a way to get the UUID from unregistered templates though (config.pvs XML parsing/regex?)
          read_all_paths.has_key?(path)
        end

        def resume
          execute('resume', @uuid)
        end

        def set_mac_address(mac)
          execute('set', @uuid, '--device-set', 'net0', '--type', 'shared', '--mac', mac)
        end

        # apply custom vm setting via set parameter
        def set_vm_settings(command)
          raw(@prlctl_path, *command)
        end

        def share_folders(folders)
          folders.each do |folder|
            # Add the shared folder
            execute('set', @uuid, '--shf-host-add', folder[:name], '--path', folder[:hostpath])
          end
        end

        def ssh_port(expected_port)
          22
        end

        def start
          execute('start', @uuid)
        end

        def suspend
          execute('suspend', @uuid)
        end

        def unregister(uuid)
          execute("unregister", uuid)
        end

        # Verifies that the driver is ready to accept work.
        #
        # This should raise a VagrantError if things are not ready.
        def verify!
          version
        end

        def version
          if execute('--version', retryable: true) =~ /prlctl version ([\d\.]+)/
            $1.downcase
          else
            raise VagrantPlugins::Parallels::Errors::ParallelsInstallIncomplete
          end
        end

        private

        def guest_execute(*command)
          execute('exec', @uuid, *command)
        end

        def json(default=nil)
          data = yield
          JSON.parse(data) rescue default
        end

        # Parse the JSON from *all* VMs and templates. Then return an array of objects (without duplicates)
        def read_all_info
          vms_arr = json({}) do
            execute('list', '--info', '--json', retryable: true).gsub(/^(INFO)?/, '')
          end
          templates_arr = json({}) do
            execute('list', '--info', '--json', '--template', retryable: true).gsub(/^(INFO)?/, '')
          end
          vms_arr | templates_arr
        end

        def read_settings(uuid=nil)
          uuid ||= @uuid
          json({}) { execute('list', uuid, '--info', '--json', retryable: true).gsub(/^(INFO)?\[/, '').gsub(/\]$/, '') }
        end

        def error_detection(command_response)
          errored = false
          # If the command was a failure, then raise an exception that is
          # nicely handled by Vagrant.
          if command_response.exit_code != 0
            if @interrupted
              @logger.info("Exit code != 0, but interrupted. Ignoring.")
            elsif command_response.exit_code == 126
              # This exit code happens if PrlCtl is on the PATH,
              # but another executable it tries to execute is missing.
              # This is usually indicative of a corrupted Parallels install.
              raise VagrantPlugins::Parallels::Errors::ParallelsErrorNotFoundError
            else
              errored = true
            end
          elsif command_response.stderr =~ /failed to open \/dev\/prlctl/i
            # This catches an error message that only shows when kernel
            # drivers aren't properly installed.
            @logger.error("Error message about unable to open prlctl")
            raise VagrantPlugins::Parallels::Errors::ParallelsErrorKernelModuleNotLoaded
          elsif command_response.stderr =~ /Unable to perform/i
            @logger.info("VM not running for command to work.")
            errored = true
          elsif command_response.stderr =~ /Invalid usage/i
            @logger.info("PrlCtl error text found, assuming error.")
            errored = true
          end
          errored
        end

        # Execute the given subcommand for PrlCtl and return the output.
        def execute(*command, &block)
          # Get the utility to execute: 'prlctl' by default and 'prlsrvctl' if it set as a first argument in command
          if command.first == :prlsrvctl
            cli = @prlsrvctl_path
            command.delete_at(0)
          else
            cli = @prlctl_path
          end

          # Get the options hash if it exists
          opts = {}
          opts = command.pop if command.last.is_a?(Hash)

          tries = opts[:retryable] ? 3 : 0

          # Variable to store our execution result
          r = nil

          # If there is an error with PrlCtl, this gets set to true
          errored = false

          retryable(on: VagrantPlugins::Parallels::Errors::ParallelsError, tries: tries, sleep: 1) do
            # Execute the command
            r = raw(cli, *command, &block)
            errored = error_detection(r)
          end

          # If there was an error running PrlCtl, show the error and the
          # output.
          if errored
            raise VagrantPlugins::Parallels::Errors::ParallelsError,
              command: command.inspect,
              stderr:  r.stderr
          end

          r.stdout
        end

        # Executes a command and returns the raw result object.
        def raw(cli, *command, &block)
          int_callback = lambda do
            @interrupted = true
            @logger.info("Interrupted.")
          end

          # Append in the options for subprocess
          command << { notify: [:stdout, :stderr] }

          Vagrant::Util::Busy.busy(int_callback) do
            Vagrant::Util::Subprocess.execute(cli, *command, &block)
          end
        end
      end
    end
  end
end
