require 'log4r'

require 'vagrant/util/platform'

require File.expand_path("../pd_8", __FILE__)

module VagrantPlugins
  module Parallels
    module Driver
      # Driver for Parallels Desktop 9.
      class PD_9 < PD_8
        def initialize(uuid)
          super(uuid)

          @logger = Log4r::Logger.new('vagrant_parallels::driver::pd_9')
        end

        def read_settings
          vm = json { execute_prlctl('list', @uuid, '--info', '--json') }
          vm.last
        end

        def read_state
          vm = json { execute_prlctl('list', @uuid, '--json') }
          return nil if !vm.last
          vm.last.fetch('status').to_sym
        end

        def read_vms
          results = {}
          vms_arr = json([]) do
            execute_prlctl('list', '--all', '--json')
          end
          templates_arr = json([]) do
            execute_prlctl('list', '--all', '--json', '--template')
          end
          vms = vms_arr | templates_arr
          vms.each do |item|
            results[item.fetch('name')] = item.fetch('uuid')
          end

          results
        end

        # Parse the JSON from *all* VMs and templates. Then return an array of objects (without duplicates)
        def read_vms_info
          vms_arr = json([]) do
            execute_prlctl('list', '--all','--info', '--json')
          end
          templates_arr = json([]) do
            execute_prlctl('list', '--all','--info', '--json', '--template')
          end
          vms_arr | templates_arr
        end

        def set_power_consumption_mode(optimized)
          state = optimized ? 'on' : 'off'
          execute_prlctl('set', @uuid, '--longer-battery-life', state)
        end
      end
    end
  end
end
