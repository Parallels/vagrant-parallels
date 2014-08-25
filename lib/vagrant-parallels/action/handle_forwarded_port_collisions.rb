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
          if env[:machine].provider.pd_version_satisfies?('>= 10')
            super
          else
            # Just continue if port forwarding is not supporting
            @app.call(env)
          end
        end

        def recover(env)
          if env[:machine].provider.pd_version_satisfies?('>= 10')
            super
          end
          # Do nothing if port forwarding is not supporting
        end
      end
    end
  end
end
