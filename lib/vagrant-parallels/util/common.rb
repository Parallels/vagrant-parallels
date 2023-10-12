require 'shellwords'

module VagrantPlugins
  module Parallels
    module Util
      module Common

        # Determines whether the VM's box contains a macOS guest for an Apple Silicon host.
        # In this case the image file ends with '.macvm' instead of '.pvm'
        def self.is_macvm(machine)
          return !machine.box.nil? && !!Dir.glob(machine.box.directory.join('*.macvm')).first
        end

        # Determines if the box directory is on an APFS filesystem
        def self.is_apfs?(path, &block)
            output = {stdout: '', stderr: ''}
            df_command = %w[df -T apfs]
            df_command << Shellwords.escape(path)
            execute(*df_command, &block).exit_code == 0
        end

        private

        def self.execute(*command, &block)
          command << { notify: [:stdout, :stderr] }

          Vagrant::Util::Busy.busy(lambda {}) do
            Vagrant::Util::Subprocess.execute(*command, &block)
          end
        end
      end
    end
  end
end
