module VagrantPlugins
  module Parallels
    module CommandSnapshot
      class Back < Vagrant.plugin(2, :command)
        def execute
          options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "Back to the current snapshot"
            opts.separator ""
            opts.separator "Usage: vagrant snapshot back [vm-name]"

            opts.on("-r", "--reload", "Run 'vagrant reload --no-provision' after \
                    restoring snapshot to ensure Vagrantfile config is applied.") do |reload|
              options[:reload] = reload
            end
          end
          # Parse the options
          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv, single_target: true) do |machine|
            snapshot_id = get_current_snapshot(machine)
            if !snapshot_id
              raise Errors::ParallelsNoSnapshot, :help => opts.help.chomp
            end

            machine.env.ui.info("Current snapshot for '#{machine.name}' is '#{snapshot_id}', reverting to it.", :color => :green)
            machine.provider.driver.execute("snapshot-switch", machine.id, "-i", snapshot_id) do |type, data|
              machine.env.ui.info(data, :color => type == :stderr ? :red : :white, :new_line => false)
            end

            if options[:reload]
              machine.env.ui.info("Reloading the VM without provision", :color => :green)
              machine.action(:reload, :provision_enabled => false)
            end
          end
        end

        def get_current_snapshot(machine)
          info = machine.provider.driver.execute("snapshot-list", machine.id)
          id = nil
          # Current snapshot id will be displayed with leading asterisk (*) symbol
          if info =~ /\*\{([\w-]*)?\}/
            id = $1
          end
          id
        end
      end
    end
  end
end