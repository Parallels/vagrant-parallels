module VagrantPlugins
  module Parallels
    module Action
      class Destroy
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::destroy')
        end

        def call(env)
          # Disable requiring password for delete action [GH-67].
          # It is available only since PD 10.
          if env[:machine].provider.pd_version_satisfies?('>= 10')
            @logger.info('Disabling password restrictions: remove-vm')
            env[:machine].provider.driver.disable_password_restrictions(['remove-vm'])
          end

          env[:ui].info I18n.t('vagrant.actions.vm.destroy.destroying')
          env[:machine].provider.driver.delete
          env[:machine].id = nil

          @app.call(env)
        end
      end
    end
  end
end
