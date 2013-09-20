module VagrantPlugins
  module Parallels
    module Action
      class IsSaved
        def initialize(app, env)
          @app = app
        end

        def call(env)

          # Set the result to be true if the machine is suspended.
          env[:result] = env[:machine].state.id == :suspended

          # Call the next if we have one (but we shouldn't, since this
          # middleware is built to run with the Call-type middlewares)
          @app.call(env)
        end
      end
    end
  end
end
