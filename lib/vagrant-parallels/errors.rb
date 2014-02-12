require "vagrant"

module VagrantPlugins
  module Parallels
    module Errors
      class VagrantParallelsError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_parallels.errors")
      end

      class PrlCtlError < VagrantParallelsError
        error_key(:prlctl_error)
      end

      class ParallelsInstallIncomplete < VagrantParallelsError
        error_key(:parallels_install_incomplete)
      end

      class ParallelsInvalidVersion < VagrantParallelsError
        error_key(:parallels_invalid_version)
      end

      class ParallelsNotDetected < VagrantParallelsError
        error_key(:parallels_not_detected)
      end

      class ParallelsNoRoomForHighLevelNetwork < VagrantParallelsError
        error_key(:parallels_no_room_for_high_level_network)
      end

      class VMInaccessible < VagrantParallelsError
        error_key(:vm_inaccessible)
      end
    end
  end
end