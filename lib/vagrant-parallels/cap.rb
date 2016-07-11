module VagrantPlugins
  module Parallels
    module Cap
      # Reads the forwarded ports that currently exist on the machine
      # itself.
      #
      # This also may not match up with configured forwarded ports, because
      # Vagrant auto port collision fixing may have taken place.
      #
      # @return [Hash<Integer, Integer>] Host => Guest port mappings.
      def self.forwarded_ports(machine)
        return nil if machine.state.id != :running

        {}.tap do |result|
          machine.provider.driver.read_forwarded_ports.each do |fp|
            result[fp[:hostport]] = fp[:guestport]
          end
        end
      end

      # Returns host's IP address that can be used to access the host machine
      # from the VM.
      #
      # @return [String] Host's IP address
      def self.host_address(machine)
        shared_iface = machine.provider.driver.read_shared_interface
        return shared_iface[:ip] if shared_iface

        nil
      end

      # Reads the network interface card MAC addresses and returns them.
      #
      # @return [Hash<Integer, String>] Adapter => MAC address
      def self.nic_mac_addresses(machine)
        nic_macs = machine.provider.driver.read_mac_addresses

        # Make numeration starting from 1, as it is expected in Vagrant.
        Hash[nic_macs.map.with_index{ |mac, index| [index+1, mac] }]
      end

      # Returns guest's IP address that can be used to access the VM from the
      # host machine.
      #
      # @return [String] Guest's IP address
      def self.public_address(machine)
        return nil if machine.state.id != :running

        ssh_info = machine.ssh_info
        return nil if !ssh_info
        ssh_info[:host]
      end

      # Returns a list of the snapshots that are taken on this machine.
      #
      # @return [Array<String>] Snapshot Name
      def self.snapshot_list(machine)
        machine.provider.driver.list_snapshots(machine.id).keys
      end
    end
  end
end
