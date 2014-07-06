require 'log4r'

module VagrantPlugins
  module Parallels
    module Action
      class SaneDefaults
        def initialize(app, env)
          @logger = Log4r::Logger.new('vagrant_parallels::action::sanedefaults')
          @app = app
        end

        def call(env)
          # Disable requiring password on such operations as creating, adding,
          # removing or coning the virtual machine. [GH-67]
          # It is available only since PD 10.
          if env[:machine].provider.pd_version_satisfies?('>= 10')
            @logger.info('Disabling any password restrictions...')
            env[:machine].provider.driver.disable_password_restrictions
          end
        end

      end
    end
  end
end
