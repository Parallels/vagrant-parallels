module VagrantPlugins
  module Parallels
    module Cap
      module NicMacAddresses
        # Reads the network interface card MAC addresses and returns them.
        #
        # @return [Hash<Integer, String>] Adapter => MAC address
        def self.nic_mac_addresses(machine)
          nic_macs = machine.provider.driver.read_mac_addresses

          # Make numeration starting from 1, as it is expected in Vagrant.
          Hash[nic_macs.map{ |index, mac| [index+1, mac] }]
        end
      end
    end
  end
end
