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
        error_key(:not_found_error)
      end

      class ParallelsErrorKernelModuleNotLoaded < VagrantParallelsError
        error_key(:kernel_module_not_loaded)
      end
    end
  end
end