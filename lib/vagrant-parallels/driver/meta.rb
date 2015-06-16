require 'forwardable'
require 'log4r'

require File.expand_path('../base', __FILE__)

module VagrantPlugins
  module Parallels
    module Driver
      class Meta < Base
        # This is raised if the VM is not found when initializing a driver
        # with a UUID.
        class VMNotFound < StandardError; end

        # We use forwardable to do all our driver forwarding
        extend Forwardable

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
          @version = read_version || ''

          # Instantiate the proper version driver for Parallels Desktop
          @logger.debug("Finding driver for Parallels Desktop version: #{@version}")
          driver_map   = {
            '8' => PD_8,
            '9' => PD_9,
            '10' => PD_10,
            '11' => PD_11
          }

          driver_klass = nil
          driver_map.each do |key, klass|
            if @version.start_with?(key)
              driver_klass = klass
              break
            end
          end

          if !driver_klass
            supported_versions = driver_map.keys.sort

            raise VagrantPlugins::Parallels::Errors::ParallelsInvalidVersion,
                  supported_versions: supported_versions.join(", ")
          end

          @logger.info("Using Parallels driver: #{driver_klass}")
          @driver = driver_klass.new(@uuid)

          if @uuid
            # Verify the VM exists, and if it doesn't, then don't worry
            # about it (mark the UUID as nil)
            raise VMNotFound if !@driver.vm_exists?(@uuid)
          end
        end

        def_delegators :@driver,
                       :clear_forwarded_ports,
                       :clear_shared_folders,
                       :compact,
                       :create_host_only_network,
                       :create_snapshot,
                       :delete,
                       :delete_disabled_adapters,
                       :delete_unused_host_only_networks,
                       :disable_password_restrictions,
                       :enable_adapters,
                       :forward_ports,
                       :halt,
                       :clone_vm,
                       :read_bridged_interfaces,
                       :read_current_snapshot,
                       :read_forwarded_ports,
                       :read_guest_ip,
                       :read_guest_tools_state,
                       :read_guest_tools_iso_path,
                       :read_host_only_interfaces,
                       :read_mac_address,
                       :read_mac_addresses,
                       :read_network_interfaces,
                       :read_shared_interface,
                       :read_shared_folders,
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
                       :set_mac_address,
                       :set_name,
                       :share_folders,
                       :ssh_ip,
                       :ssh_port,
                       :start,
                       :suspend,
                       :unregister,
                       :vm_exists?

        protected

        # This returns the version of Parallels Desktop that is running.
        #
        # @return [String]
        def read_version
          # The version string is usually in one of the following formats:
          #
          # * prlctl version 8.0.12345.123456
          # * prlctl version 9.0.12345.123456
          # * prlctl version 10.0.0 (12345) rev 123456
          #
          # But we need exactly the first 3 numbers: "x.x.x"

          if execute_prlctl('--version') =~ /prlctl version (\d+\.\d+.\d+)/
            return $1
          end

          nil
        end
      end
    end
  end
end
