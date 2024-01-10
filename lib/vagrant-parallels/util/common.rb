module VagrantPlugins
  module Parallels
    module Util
      module Common

        # Determines whether the VM's box contains a macOS guest for an Apple Silicon host.
        # In this case the image file ends with '.macvm' instead of '.pvm'
        def self.is_macvm(machine)
          return !machine.box.nil? && !!Dir.glob(machine.box.directory.join('*.macvm')).first
        end

      end
    end
  end
end
