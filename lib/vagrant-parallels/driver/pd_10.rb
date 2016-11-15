require 'log4r'

require 'vagrant/util/platform'

require_relative 'base'

module VagrantPlugins
  module Parallels
    module Driver
      # Driver for Parallels Desktop 10.
      class PD_10 < Base
        def initialize(uuid)
          super(uuid)

          @logger = Log4r::Logger.new('vagrant_parallels::driver::pd_10')
        end
      end
    end
  end
end
