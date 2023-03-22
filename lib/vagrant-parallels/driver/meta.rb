require 'forwardable'
require 'log4r'

require_relative 'base'

module VagrantPlugins
  module Parallels
    module Driver
      class Meta < Base
        # This is raised if the VM is not found when initializing a driver
        # with a UUID.
        class VMNotFound < StandardError; end

        # We use forwardable to do all our driver forwarding
        extend Forwardable

        # We cache the Parallels Desktop version here once we have one,
        # since during the execution of Vagrant, it likely doesn't change.
        @@version = nil
        @@version_lock = Mutex.new

        # The UUID of the virtual machine we represent
        attr_reader :uuid

        # The version of Parallels Desktop that is running.
        attr_reader :version

        def initialize(uuid=nil)
          # Setup the base
          super(uuid)

          @logger = Log4r::Logger.new('vagrant_parallels::driver::meta')
          @uuid = uuid

          # Read and assign the version of Parallels Desktop we know which
          # specific driver to instantiate.
          @@version_lock.synchronize do
            @@version = read_version
          end

          # Instantiate the proper version driver for Parallels Desktop
          @logger.debug("Finding driver for Parallels Desktop version: #{@@version}")

          major_ver = @@version.split('.').first.to_i
          driver_klass =
            case major_ver
            when 1..10 then raise Errors::ParallelsUnsupportedVersion
            when 11 then PD_11
            else PD_12
            end

          # Starting since PD 11 only Pro and Business editions have CLI
          # functionality and can be used with Vagrant.
          edition = read_edition
          if !edition || !%w(any pro business).include?(edition)
            raise Errors::ParallelsUnsupportedEdition
          end

          @logger.info("Using Parallels driver: #{driver_klass}")
          @driver = driver_klass.new(@uuid)
          @version = @@version

          if @uuid
            # Verify the VM exists, and if it doesn't, then don't worry
            # about it (mark the UUID as nil)
            raise VMNotFound if !@driver.vm_exists?(@uuid)
          end
        end

        def_delegators :@driver,
                       :clear_forwarded_ports,
                       :clear_shared_folders,
                       :compact_hdd,
                       :connect_network_interface,
                       :create_host_only_network,
                       :create_snapshot,
                       :delete,
                       :delete_disabled_adapters,
                       :delete_unused_host_only_networks,
                       :disable_password_restrictions,
                       :enable_adapters,
                       :execute_prlctl,
                       :forward_ports,
                       :halt,
                       :clone_vm,
                       :list_snapshots,
                       :read_bridged_interfaces,
                       :read_current_snapshot,
                       :read_forwarded_ports,
                       :read_guest_ip_dhcp,
                       :read_guest_ip_prlctl,
                       :read_guest_tools_state,
                       :read_guest_tools_iso_path,
                       :read_host_only_interfaces,
                       :read_mac_address,
                       :read_mac_addresses,
                       :read_network_interfaces,
                       :read_shared_interface,
                       :read_shared_folders,
                       :read_shared_network_id,
                       :read_settings,
                       :read_state,
                       :read_used_ports,
                       :read_virtual_networks,
                       :read_vm_option,
                       :read_vms,
                       :read_vms_info,
                       :regenerate_src_uuid,
                       :register,
                       :resume,
                       :set_power_consumption_mode,
                       :set_name,
                       :share_folders,
                       :ssh_ip,
                       :ssh_port,
                       :start,
                       :suspend,
                       :unregister,
                       :vm_exists?

        protected

        # Returns the edition of Parallels Desktop that is running. It makes
        # sense only for Parallels Desktop 11 and later. For older versions
        # it returns nil.
        #
        # @return [String]
        def read_edition
          lic_info = json do
            execute(@prlsrvctl_path, 'info', '--license', '--json')
          end
          lic_info['edition']
        end

        # This returns the version of Parallels Desktop that is running.
        #
        # @return [String]
        def read_version
          # The version string is usually in one of the following formats:
          #
          # * prlctl version 8.0.12345.123456
          # * prlctl version 9.0.12345.123456
          # * prlctl version 10.0.0 (12345) rev 123456
          # * prlctl version 14.0.1 (45154)
          #
          # But we need exactly the first 3 numbers: "x.x.x"
          output = execute(@prlctl_path, '--version')

          if output =~ /prlctl version (\d+\.\d+.\d+)/
            Regexp.last_match(1)
          else
            raise Errors::ParallelsInvalidVersion, output: output
          end
        end
      end
    end
  end
end
