module VagrantPlugins
  module Parallels
    module CommandSnapshot
      class List < Vagrant.plugin(2, :command)
        def execute
          options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "List snapshot IDs"
            opts.separator ""
            opts.separator "Usage: vagrant prl-snapshot list [vm-name]"

            opts.on("-t", "--tree", "Draw the tree.") do |t|
              options[:tree] = t
            end
          end
          # Parse the options
          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv, single_target: true) do |machine|
            cmd = ["snapshot-list", machine.id]
            cmd << "--tree" if options[:tree]
            machine.env.ui.info("Listing snapshot IDs for '#{machine.name}':", :color => :green)
            res = machine.provider.driver.execute(*cmd) do |type, data|
              machine.env.ui.info(data, :color => type == :stderr ? :red : :white)
            end
          end
        end
      end
    end
  end
end