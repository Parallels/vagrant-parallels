require "vagrant"

module VagrantPlugins
  module Parallels
    module Errors
      class VagrantParallelsError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_parallels.errors")
      end

      class ParallelsError < VagrantParallelsError
        error_key(:prlctl_error)
      end

      class ParallelsErrorNotFoundError < VagrantParallelsError
        error_key(:prlctl_not_found_error)
      end

      class ParallelsErrorKernelModuleNotLoaded < VagrantParallelsError
        error_key(:parallels_kernel_module_not_loaded)
      end

      class ParallelsNoRoomForHighLevelNetwork < VagrantParallelsError
        error_key(:parallels_no_room_for_high_level_network)
      end

      class ParallelsNoSnapshot < VagrantParallelsError
        error_key(:parallels_no_snapshot)
      end

      class ParallelsSnapshotNameRequired < VagrantParallelsError
        error_key(:parallels_snapshot_name_required)
      end

      class ParallelsSnapshotIdRequired < VagrantParallelsError
        error_key(:parallels_snapshot_id_required)
      end
    end
  end
end