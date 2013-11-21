module VagrantPlugins
  module Parallels
    module CommandSnapshot
      class Go < Vagrant.plugin(2, :command)
        def execute
          options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "Go to specified snapshot"
            opts.separator ""
            opts.separator "Usage: vagrant snapshot go [vm-name] <SNAPSHOT_ID>"

            opts.on("-r", "--reload", "Run 'vagrant reload --no-provision' after \
                    restoring snapshot to ensure Vagrantfile config is applied.") do |reload|
              options[:reload] = reload
            end
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
            machine.env.ui.info("Reverting '#{machine.name}' to snapshot '#{snapshot_id}'", :color => :green)
            machine.provider.driver.execute("snapshot-switch", machine.id, "-i", snapshot_id) do |type, data|
              machine.env.ui.info(data, :color => type == :stderr ? :red : :white, :new_line => false)
            end

            if options[:reload]
              machine.env.ui.info("Reloading the VM without provision", :color => :green)
              machine.action(:reload, :provision_enabled => false)
            end
          end
        end
      end
    end
  end
end