module VagrantPlugins
  module Parallels
    module CommandSnapshot
      class Take < Vagrant.plugin(2, :command)
        def execute
          opts = OptionParser.new do |opts|
            opts.banner = "Take snapshot"
            opts.separator ""
            opts.separator "Usage: vagrant snapshot take [vm-name] <SNAPSHOT_NAME>"
          end
          # Parse the options
          argv = parse_options(opts)
          return if !argv

          snapshot_name = argv.pop
          vm_name = argv.pop
          if !snapshot_name
            raise Errors::ParallelsSnapshotNameRequired, :help => opts.help.chomp
          end

          with_target_vms(vm_name, single_target: true) do |machine|
            machine.env.ui.info("Taking snapshot '#{snapshot_name}' for '#{machine.name}'", :color => :green)
            machine.provider.driver.execute("snapshot", machine.id, "-n", snapshot_name) do |type, data|
              machine.env.ui.info(data, :color => type == :stderr ? :red : :white, :new_line => false)
            end
          end
        end
      end
    end
  end
end