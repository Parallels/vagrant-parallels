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

          @logger = Log4r::Logger.new("vagrant::provider::parallels::pd_9")
        end

        def read_settings
          vm = json { execute('list', @uuid, '--info', '--json', retryable: true) }
          vm.last
        end

        def read_state
          vm = json { execute('list', @uuid, '--json', retryable: true) }
          return nil if !vm.last
          vm.last.fetch('status').to_sym
        end

        def read_vms
          results = {}
          vms_arr = json([]) do
            execute('list', '--all', '--json', retryable: true)
          end
          templates_arr = json([]) do
            execute('list', '--all', '--json', '--template', retryable: true)
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
            execute('list', '--all','--info', '--json', retryable: true)
          end
          templates_arr = json([]) do
            execute('list', '--all','--info', '--json', '--template', retryable: true)
          end
          vms_arr | templates_arr
        end

        def set_power_consumption_mode(optimized)
          state = optimized ? 'on' : 'off'
          execute('set', @uuid, '--longer-battery-life', state)
        end
      end
    end
  end
end
