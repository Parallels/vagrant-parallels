module VagrantPlugins
  module Parallels
    module Cap
      module HostAddress
        def self.host_address(machine)

          shared_iface = machine.provider.driver.read_shared_interface
          return shared_iface[:ip] if shared_iface

          nil
        end
      end
    end
  end
end
