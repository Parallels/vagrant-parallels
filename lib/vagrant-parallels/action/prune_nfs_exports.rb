module VagrantPlugins
  module Parallels
    module Action
      class PruneNFSExports
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:host]
            vms = env[:machine].provider.driver.read_all_names
            env[:host].nfs_prune(vms.values)
          end

          @app.call(env)
        end
      end
    end
  end
end
