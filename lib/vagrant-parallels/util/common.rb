module VagrantPlugins
  module Parallels
    module Util
      module Common

        # Determines whether the VM's box contains a macOS guest for an Apple Silicon host.
        # In this case the image file ends with '.macvm' instead of '.pvm'
        def is_macvm(env)
          return !!Dir.glob(env[:machine].box.directory.join('*.macvm')).first
        end

      end
    end
  end
end
