require 'log4r'

require 'vagrant/util/platform'

require_relative 'pd_11'

module VagrantPlugins
  module Parallels
    module Driver
      # Driver for Parallels Desktop 12.
      class PD_12 < PD_11
        def initialize(uuid)
          super(uuid)

          @logger = Log4r::Logger.new('vagrant_parallels::driver::pd_12')
        end
      end
    end
  end
end
