require 'log4r'
require 'json'

require 'vagrant/util/busy'
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

        attr_reader :uuid

        def initialize(uuid)
          @logger = Log4r::Logger.new("vagrant::provider::parallels::prlctl")

          # This flag is used to keep track of interrupted state (SIGINT)
          @interrupted = false

          # Store machine id
          @uuid = uuid

          # Set the path to prlctl
          @manager_path = "prlctl"

          @logger.info("Parallels path: #{@manager_path}")
        end

        # Returns the current state of this VM.
        #
        # @return [Symbol]
        def read_state
          read_settings(@uuid).fetch('State', 'inaccessible').to_sym
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
            list[File.realpath item.fetch('Home')] = item.fetch('ID')
          end

          list
        end

        def read_mac_address
          read_settings.fetch('Hardware', {}).fetch('net0', {}).fetch('mac', nil)
        end

        # Verifies that the driver is ready to accept work.
        #
        # This should raise a VagrantError if things are not ready.
        def verify!
          # TODO: Use version method?
          execute('--version')
        end

        def version
          raw_version = execute('--version', retryable: true)
          raw_version.gsub('/prlctl version /', '')
        end

        def clear_shared_folders
          read_settings.fetch("Host Shared Folders", {}).keys.drop(1).each do |folder|
            execute("set", @uuid, "--shf-host-del", folder)
          end
        end

        def optimize_disk
          env.ui.info "Optimizing Disk"
          path_to_hdd = File.join read_settings.fetch("Home"), "harddisk.hdd"
          optimize_command = "#{@prldisktool} compact --buildmap --hdd #{path_to_hdd}"
          shell_exec optimize_command
        end

        def import(template_uuid, vm_name)
          last = 0
          execute("clone", template_uuid, '--name', vm_name) do |type, data|
            lines = data.split("\r")
            # The progress of the import will be in the last line. Do a greedy
            # regular expression to find what we're looking for.
            if lines.last =~ /.+?(\d{,3})%/
              current = $1.to_i
              if current > last
                last = current
                yield current if block_given?
              end
            end
          end
          @uuid = read_settings(vm_name).fetch('ID', vm_name)
        end

        def delete_adapters
          read_settings.fetch('Hardware').each do |k, _|
            if k != 'net0' and k.start_with? 'net'
              execute('set', @uuid, '--device-del', k)
            end
          end
        end

        def resume
          execute('resume', @uuid)
        end

        def suspend
          execute('suspend', @uuid)
        end

        def start
          execute('start', @uuid)
        end

        def halt(force=false)
          args = ['stop', @uuid]
          args << '--kill' if force
          execute(*args)
        end

        def delete
          execute('delete', @uuid)
        end

        def export(path, vm_name)
          last = 0
          execute("clone", @uuid, "--name", vm_name, "--template", "--dst", path.to_s) do |type, data|
            lines = data.split("\r")
            # The progress of the import will be in the last line. Do a greedy
            # regular expression to find what we're looking for.
            if lines.last =~ /.+?(\d{,3})%/
              current = $1.to_i
              if current > last
                last = current
                yield current if block_given?
              end
            end
          end

          new_vm = read_settings(vm_name).fetch('ID', vm_name)
          compress(new_vm)
          new_vm
        end

        def compress(uuid=nil)
          uuid ||= @uuid
          path_to_hdd = read_settings(uuid).fetch("Hardware", {}).fetch("hdd0", {}).fetch("image", nil)
          raw('prl_disk_tool', 'compact', '--buildmap', '--hdd', path_to_hdd) if path_to_hdd
        end

        def register(pvm_file)
          execute("register", pvm_file)
        end

        def unregister(uuid)
          execute("unregister", uuid)
        end

        def registered?(path)
          # TODO: Make this take UUID and have callers pass that instead
          # Need a way to get the UUID from unregistered templates though (config.pvs XML parsing/regex?)
          read_all_paths.has_key?(path)
        end

        def set_mac_address(mac)
          execute('set', @uuid, '--device-set', 'net0', '--type', 'shared', '--mac', mac)
        end

        def ssh_port(expected_port)
          22
        end

        def read_guest_tools_version
          read_settings.fetch('GuestTools', {}).fetch('version', nil)
        end

        def share_folders(folders)
          folders.each do |folder|
            # Add the shared folder
            execute('set', @uuid, '--shf-host-add', folder[:name], '--path', folder[:hostpath])
          end
        end

        def ready?
          !!guest_execute('uname') rescue false
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

        private

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

        def json(default=nil)
          data = yield
          JSON.parse(data) rescue default
        end

        def guest_execute(*command)
          execute('exec', @uuid, *command)
        end

        # Execute the given subcommand for PrlCtl and return the output.
        def execute(*command, &block)
          # Get the options hash if it exists
          opts = {}
          opts = command.pop if command.last.is_a?(Hash)

          tries = 0
          tries = 3 if opts[:retryable]

          # Variable to store our execution result
          r = nil

          # If there is an error with PrlCtl, this gets set to true
          errored = false

          retryable(on: VagrantPlugins::Parallels::Errors::ParallelsError, tries: tries, sleep: 1) do
            # Execute the command
            r = raw(@manager_path, *command, &block)

            # If the command was a failure, then raise an exception that is
            # nicely handled by Vagrant.
            if r.exit_code != 0
              if @interrupted
                @logger.info("Exit code != 0, but interrupted. Ignoring.")
              elsif r.exit_code == 126
                # This exit code happens if PrlCtl is on the PATH,
                # but another executable it tries to execute is missing.
                # This is usually indicative of a corrupted Parallels install.
                raise VagrantPlugins::Parallels::Errors::ParallelsErrorNotFoundError
              else
                errored = true
              end
            else
              if r.stderr =~ /failed to open \/dev\/prlctl/i
                # This catches an error message that only shows when kernel
                # drivers aren't properly installed.
                @logger.error("Error message about unable to open prlctl")
                raise VagrantPlugins::Parallels::Errors::ParallelsErrorKernelModuleNotLoaded
              end

              if r.stderr =~ /Unable to perform/i
                @logger.info("VM not running for command to work.")
                errored = true
              elsif r.stderr =~ /Invalid usage/i
                @logger.info("PrlCtl error text found, assuming error.")
                errored = true
              end
            end
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
