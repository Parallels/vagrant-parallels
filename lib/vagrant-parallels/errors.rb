require 'vagrant'

module VagrantPlugins
  module Parallels
    module Errors
      class VagrantParallelsError < Vagrant::Errors::VagrantError
        error_namespace('vagrant_parallels.errors')
      end

      class DhcpLeasesNotAccessible < VagrantParallelsError
        error_key(:dhcp_leases_file_not_accessible)
      end

      class LinuxMountFailed < VagrantParallelsError
        error_key(:linux_mount_failed)
      end

      class LinuxPrlFsInvalidOptions < VagrantParallelsError
        error_key(:linux_prl_fs_invalid_options)
      end

      class MacOSXRequired < VagrantParallelsError
        error_key(:mac_os_x_required)
      end

      class ExecutionError < VagrantParallelsError
        error_key(:execution_error)
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

      class ParallelsToolsIsoNotFound < VagrantParallelsError
        error_key(:parallels_tools_iso_not_found)
      end

      class ParallelsTplNameNotFound < VagrantParallelsError
        error_key(:parallels_tpl_name_not_found)
      end

      class ParallelsVMOptionNotFound < VagrantParallelsError
        error_key(:parallels_vm_option_not_found)
      end

      class ParallelsUnsupportedEdition < VagrantParallelsError
        error_key(:parallels_unsupported_edition)
      end

      class ParallelsUnsupportedVersion < VagrantParallelsError
        error_key(:parallels_unsupported_version)
      end

      class SharedAdapterNotFound < VagrantParallelsError
        error_key(:shared_adapter_not_found)
      end

      class SnapshotIdNotDetected < VagrantParallelsError
        error_key(:snapshot_id_not_detected)
      end

      class VMImportFailure < VagrantParallelsError
        error_key(:vm_import_failure)
      end

      class VMNameExists < VagrantParallelsError
        error_key(:vm_name_exists)
      end
    end
  end
end