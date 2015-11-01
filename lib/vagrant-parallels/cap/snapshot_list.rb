module VagrantPlugins
  module Parallels
    module Cap
      module SnapshotList
        # Returns a list of the snapshots that are taken on this machine.
        #
        # @return [Array<String>] Snapshot Name
        def self.snapshot_list(machine)
          machine.provider.driver.list_snapshots(machine.id).keys
        end
      end
    end
  end
end
