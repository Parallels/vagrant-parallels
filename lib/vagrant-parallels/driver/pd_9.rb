require 'log4r'

require 'vagrant/util/platform'

require_relative 'pd_8'

module VagrantPlugins
  module Parallels
    module Driver
      # Driver for Parallels Desktop 9.
      class PD_9 < PD_8
        def initialize(uuid)
          super(uuid)

          @logger = Log4r::Logger.new('vagrant_parallels::driver::pd_9')
        end

        def set_power_consumption_mode(optimized)
          state = optimized ? 'on' : 'off'
          execute_prlctl('set', @uuid, '--longer-battery-life', state)
        end
      end
    end
  end
end
