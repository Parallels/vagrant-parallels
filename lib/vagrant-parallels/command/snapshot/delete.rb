module VagrantPlugins
  module Parallels
    module CommandSnapshot
      class Delete < Vagrant.plugin(2, :command)
        def execute
          opts = OptionParser.new do |opts|
            opts.banner = "Delete snapshot (warning: this operation can be slow)"
            opts.separator ""
            opts.separator "Usage: vagrant snapshot delete [vm-name] <SNAPSHOT_ID>"
          end
          # Parse the options
          argv = parse_options(opts)
          return if !argv

          snapshot_id = argv.pop
          vm_name = argv.pop
          if !snapshot_id
            raise Errors::ParallelsSnapshotIdRequired, :help => opts.help.chomp
          end

          with_target_vms(vm_name, single_target: true) do |machine|
            machine.provider.driver.execute("snapshot-delete", machine.id, "--id", snapshot_id) do |type, data|
              machine.env.ui.info(data, :color => type == :stderr ? :red : :white)
            end
          end
        end
      end
    end
  end
end