module VagrantPlugins
  module Parallels
    module Cap
      module NicMacAddresses
        # Reads the network interface card MAC addresses and returns them.
        #
        # @return [Hash<String, String>] Adapter => MAC address
        def self.nic_mac_addresses(machine)
          machine.provider.driver.read_mac_addresses
        end
      end
    end
  end
end
