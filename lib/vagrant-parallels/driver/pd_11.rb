require 'log4r'

require 'vagrant/util/platform'

require_relative 'pd_10'

module VagrantPlugins
  module Parallels
    module Driver
      # Driver for Parallels Desktop 11.
      class PD_11 < PD_10
        def initialize(uuid)
          super(uuid)

          @logger = Log4r::Logger.new('vagrant_parallels::driver::pd_11')
        end
      end
    end
  end
end
