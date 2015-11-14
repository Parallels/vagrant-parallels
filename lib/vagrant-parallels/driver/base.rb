require 'log4r'

require 'vagrant/util/busy'
require 'vagrant/util/network_ip'
require 'vagrant/util/platform'
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

          @prlctl_path    = util_path('prlctl')
          @prlsrvctl_path = util_path('prlsrvctl')
          @prldisktool_path = util_path('prl_disk_tool')

          if !@prlctl_path
            # This means that Parallels Desktop was not found, so we raise this
            # error here.
            raise VagrantPlugins::Parallels::Errors::ParallelsNotDetected
          end

          @logger.info("prlctl path: #{@prlctl_path}")
          @logger.info("prlsrvctl path: #{@prlsrvctl_path}")
        end

        # Removes all port forwarding rules for the virtual machine.
        def clear_forwarded_ports
          raise NotImplementedError
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
        # @param [String] dst_name Name of the destination VM.
        # @param [<String => String>] options Options to clone virtual machine.
        # @return [String] UUID of the new VM.
        def clone_vm(src_name, dst_name, options={})
          args = ['clone', src_name, '--name', dst_name]
          args << '--template' if options[:template]
          args.concat(['--dst', options[:dst]]) if options[:dst]

          # Linked clone options
          args << '--linked' if options[:linked]
          args.concat(['--id', options[:snapshot_id]]) if options[:snapshot_id]

          execute_prlctl(*args) do |_, data|
            lines = data.split('\r')
            # The progress of the clone will be in the last line. Do a greedy
            # regular expression to find what we're looking for.
            if lines.last =~ /Copying hard disk.+?(\d{,3}) ?%/
              yield $1.to_i if block_given?
            end
          end

          # copy any ISO files from the template to the clone. unfortunately
          # this is not done by prlctl clone
          clone_home = read_settings(dst_name).fetch('Home')
          iso_files = Dir[File.join(read_settings(src_name).fetch('Home'), '*.iso')]
          iso_files.each do |file|
              FileUtils.cp(file, clone_home)
          end

          read_vms[dst_name]
        end

        # Compacts all disk drives of virtual machine
        def compact(uuid)
          hw_info = read_settings(uuid).fetch('Hardware', {})
          used_drives = hw_info.select do |name, _|
            name.start_with? 'hdd'
          end
          used_drives.each_value do |drive_params|
            execute(@prldisktool_path, 'compact', '--hdd', drive_params['image']) do |_, data|
              lines = data.split('\r')
              # The progress of the compact will be in the last line. Do a greedy
              # regular expression to find what we're looking for.
              if lines.last =~ /.+?(\d{,3}) ?%/
                yield $1.to_i if block_given?
              end
            end
          end
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
            name:    options[:network_id],
            ip:      options[:adapter_ip],
            netmask: options[:netmask],
            dhcp:    options[:dhcp]
          }
        end

        # Creates a snapshot for the specified virtual machine.
        #
        # @param [String] uuid Name or UUID of the target VM.
        # @param [<Symbol => String, Boolean>] options Snapshot options.
        # @return [String] ID of the created snapshot.
        def create_snapshot(uuid, options)
          raise NotImplementedError
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

        # Deletes any host only networks that aren't being used for anything.
        def delete_unused_host_only_networks
          raise NotImplementedError
        end

        # Disables requiring password on such operations as creating, adding,
        # removing or cloning the virtual machine.
        #
        # @param [Array<String>] acts List of actions. Available values:
        # ['create-vm', 'add-vm', 'remove-vm', 'clone-vm']
        def disable_password_restrictions(acts)
          raise NotImplementedError
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
          raise NotImplementedError
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
          raise NotImplementedError
        end

        # Halts the virtual machine (pulls the plug).
        def halt(force=false)
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
            info[:name]    = iface
            info[:ip]      = '0.0.0.0'
            info[:netmask] = '0.0.0.0'
            info[:status]  = 'Down'

            if ifconfig =~ /(?<=inet\s)(\S*)/
              info[:ip] = $1.to_s
            end
            if ifconfig =~ /(?<=netmask\s)(\S*)/
              # Netmask will be converted from hex to dec:
              # '0xffffff00' -> '255.255.255.0'
              info[:netmask] = $1.hex.to_s(16).scan(/../).each.map{|octet| octet.hex}.join('.')
            end
            if ifconfig =~ /\W(UP)\W/ and ifconfig !~ /(?<=status:\s)inactive$/
              info[:status] = 'Up'
            end

            bridged_ifaces << info
          end
          bridged_ifaces
        end

        # Returns current snapshot ID for the specified VM. Returns nil if
        # the VM doesn't have any snapshot.
        #
        # @param [String] uuid Name or UUID of the target VM.
        # @return [String]
        def read_current_snapshot(uuid)
          raise NotImplementedError
        end

        def read_forwarded_ports(global=false)
          raise NotImplementedError
        end

        # Returns an IP of the virtual machine. It requires that Shared network
        # adapter is configured for this VM and it obtains an IP via DHCP.
        #
        # @return [String] IP address leased by DHCP server in "Shared" network
        def read_guest_ip
          mac_addr = read_mac_address.downcase
          leases_file = '/Library/Preferences/Parallels/parallels_dhcp_leases'
          leases = {}
          begin
            File.open(leases_file).grep(/#{mac_addr}/) do |line|
              _, ip, exp, dur, _, _ = line.split /([\d.]*)="(\d*),(\d*),(\w*),(\w*)".*/
              leases[ip] = exp.to_i - dur.to_i
            end
          rescue Errno::EACCES
            raise Errors::DhcpLeasesNotAccessible, :leases_file => leases_file.to_s
          rescue Errno::ENOENT
            # File does not exist
            # Perhaps, it is the fist start of Parallels Desktop
            return nil
          end

          return nil if leases.empty?

          # Get the most resent lease and return an associated IP
          leases.sort_by { |_ip, lease_time| lease_time }.last.first
        end

        # Returns path to the Parallels Tools ISO file.
        #
        # @param [String] guest_os Guest os type: "linux", "darwin" or "windows"
        # @return [String] Path to the ISO.
        def read_guest_tools_iso_path(guest_os)
          guest_os = guest_os.to_sym
          iso_name ={
            linux: 'prl-tools-lin.iso',
            darwin: 'prl-tools-mac.iso',
            windows: 'prl-tools-win.iso'
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
          state = 'not_installed' if !state
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
        #
        # @return [Array<Symbol => String>]
        def read_host_only_interfaces
          raise NotImplementedError
        end

        # Returns the MAC address of the first Shared network interface.
        #
        # @return [String]
        def read_mac_address
          hw_info = read_settings.fetch('Hardware', {})
          shared_ifaces = hw_info.select do |name, params|
            name.start_with?('net') && params['type'] == 'shared'
          end

          if shared_ifaces.empty?
            raise Errors::SharedAdapterNotFound
          end

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
          raise NotImplementedError
        end

        # Returns virtual machine settings
        #
        # @return [<String => String, Hash>]
        def read_settings(uuid=@uuid)
          vm = json { execute_prlctl('list', uuid, '--info', '--no-header', '--json')  }
          vm.last
        end

        # Returns the unique name (e.q. "ID") on the first Shared network in
        # Parallels Desktop configuration.
        # By default there is only one called "Shared".
        #
        # @return [String] Shared network ID
        def read_shared_network_id
          # There should be only one Shared interface
          shared_net = read_virtual_networks.detect do |net|
            net['Type'] == 'shared'
          end
          shared_net.fetch('Network ID')
        end

        # Returns info about shared network interface.
        #
        # @return [<Symbol => String, Hash>]
        def read_shared_interface
          raise NotImplementedError
        end

        # Returns a list of shared folders in format:
        # { id => hostpath, ... }
        #
        # @return [<String => String>]
        def read_shared_folders
          shf_info = read_settings.fetch('Host Shared Folders', {})
          list = {}
          shf_info.delete_if { |k,v| k == 'enabled' }.each do |id, data|
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
        def read_vm_option(option, uuid=@uuid)
          out = execute_prlctl('list', uuid,'--no-header', '-o', option).strip
          if out.empty?
            raise Errors::ParallelsVMOptionNotFound, vm_option: option
          end

          out
        end

        # Returns names and ids of all virtual machines and templates.
        #
        # @return [<String => String>]
        def read_vms
          args = %w(list --all --no-header --json -o name,uuid)
          vms_arr = json { execute_prlctl(*args) }
          templates_arr = json { execute_prlctl(*args, '--template') }

          vms = vms_arr | templates_arr
          Hash[vms.map { |i| [i.fetch('name'), i.fetch('uuid')] }]
        end

        # Returns the configuration of all VMs and templates.
        #
        # @return [Array <String => String>]
        def read_vms_info
          args = %w(list --all --info --no-header --json)
          vms_arr = json { execute_prlctl(*args) }
          templates_arr = json { execute_prlctl(*args, '--template') }

          vms_arr | templates_arr
        end

        # Regenerates 'SourceVmUuid' to avoid SMBIOS UUID collision [GH-113]
        #
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

        # Registers the virtual machine
        #
        # @param [String] pvm_file Path to the machine image (*.pvm)
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
          execute(*args)
        end

        # Resumes the virtual machine.
        #
        def resume
          execute_prlctl('resume', @uuid)
        end

        # Sets the name of the virtual machine.
        #
        # @param [String] name New VM name.
        def set_name(name)
          execute_prlctl('set', @uuid, '--name', name)
        end

        # Sets Power Consumption method.
        #
        # @param [Boolean] optimized Use "Longer Battery Life"
        # instead "Better Performance"
        def set_power_consumption_mode(optimized)
          raise NotImplementedError
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

        # Reads the SSH IP of this VM.
        #
        # @return [String] IP address to use for SSH connection to the VM.
        def ssh_ip
          read_guest_ip
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
          execute(*args)
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

        private

        # Wraps 'execute' and returns the output of given 'prlctl' subcommand.
        def execute_prlctl(*command, &block)
          execute(@prlctl_path, *command, &block)
        end

        #Wraps 'execute' and returns the output of given 'prlsrvctl' subcommand.
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
                :command => command.inspect,
                :stderr  => r.stderr
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
            if raise_error
              raise VagrantPlugins::Parallels::Errors::JSONParseError, data: data
            end

            # Remove garbage before/after json string[GH-204]
            data = data[/(\{.*\}|\[.*\])/m]

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
          command << {notify: [:stdout, :stderr]}

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
