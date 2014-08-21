module VagrantPlugins
  module Parallels
    module Action
      class HandleForwardedPortCollisions < Vagrant::Action::Builtin::HandleForwardedPortCollisions
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::handle_port_collisions')
        end

        # This middleware just wraps the builtin action and allows to skip it if
        # port forwarding is not supported for current Parallels Desktop version.
        def call(env)
          # Port Forwarding feature is available only with PD >= 10
          if !env[:machine].provider.pd_version_satisfies?('>= 10')
            return @app.call(env)
          end

          # Call the builtin action
          super
        end
      end
    end
  end
end
