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
          read_settings(@uuid).fetch('status', 'error').to_sym
        end

        # Returns a list of all UUIDs of virtual machines currently
        # known by Parallels.
        #
        # @return [Array<String>]
        def list_vms
          read_vms.map do |item|
            item.fetch('name')
          end
        end

        def read_mac_address
          read_settings.fetch('Hardware', {}).fetch('net0', {}).fetch('mac', nil)
        end

        # Verifies that the driver is ready to accept work.
        #
        # This should raise a VagrantError if things are not ready.
        def verify!
          execute('--version')
        end

        def clear_shared_folders
          read_settings.fetch("Host Shared Folders", {}).keys.drop(1).each do |folder|
            execute("set", @uuid, "--shf-host-del", folder)
          end
        end

        def import(template_name, vm_name)
          last = 0
          execute("clone", template_name, '--name', vm_name) do |type, data|
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

        def resume
          execute('resume', @uuid)
        end

        def suspend
          execute('suspend', @uuid)
        end

        def start
          execute('start', @uuid)
        end

        def halt
          execute('stop', @uuid, '--kill')
        end

        def delete
          execute('delete', @uuid)
        end

        def register(pvm_file)
          execute("register", pvm_file)
        end

        def unregister(uuid)
          execute("unregister", uuid)
        end

        def registered?(uuid)
          !read_settings(uuid).empty?
        end

        def set_mac_address(mac)
          execute('set', @uuid, '--device-set', 'net0', '--type', 'shared', '--mac', (mac || 'auto'))
        end

        def ssh_port(expected_port)
          22
        end

        def read_guest_additions_version
          read_settings.fetch('GuestTools', {}).fetch('version', nil)
        end

        def share_folders(folders)
          folders.each do |folder|
            # Add the shared folder
            execute('set', @uuid, '--shf-host-add', folder[:name], '--path', folder[:hostpath])
          end
        end

        def symlink(folder, path)
          guest_execute('ln', '-s', Pathname.new('/media/psf').join(folder).to_s, path)
        end

        def execute_command(command)
          raw(*command)
        end

      private

        def read_settings(uuid=nil)
          uuid ||= @uuid
          output = execute('list', uuid, '--info', '--json', :retryable => true)
          JSON.parse(output.gsub(/^INFO/, '')).first
        rescue
          {}
        end

        def read_vms
          output = execute('list', '--all', '--json', :retryable => true)
          JSON.parse(output)
        rescue
          []
        end

        def read_templates
          output = execute('list', '--template', '--json', :retryable => true)
          JSON.parse(output)
        rescue
          []
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

          retryable(:on => VagrantPlugins::Parallels::Errors::ParallelsError, :tries => tries, :sleep => 1) do
            # Execute the command
            r = raw(*command, &block)

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

              if r.stderr =~ /Invalid usage/
                @logger.info("PrlCtl error text found, assuming error.")
                errored = true
              end
            end
          end

          # If there was an error running PrlCtl, show the error and the
          # output.
          if errored
            raise VagrantPlugins::Parallels::Errors::ParallelsError,
              :command => command.inspect,
              :stderr  => r.stderr
          end

          r.stdout
        end

        # Executes a command and returns the raw result object.
        def raw(*command, &block)
          int_callback = lambda do
            @interrupted = true
            @logger.info("Interrupted.")
          end

          # Append in the options for subprocess
          command << { :notify => [:stdout, :stderr] }

          Vagrant::Util::Busy.busy(int_callback) do
            Vagrant::Util::Subprocess.execute(@manager_path, *command, &block)
          end
        end
      end
    end
  end
end
