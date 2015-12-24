module VagrantPlugins
  module Parallels
    module Action
      class SnapshotRestore
        def initialize(app, env)
          @app = app
        end

        def call(env)
          snapshots = env[:machine].provider.driver.list_snapshots(env[:machine].id)
          snapshot_id = snapshots[env[:snapshot_name]]

          env[:ui].info I18n.t('vagrant.actions.vm.snapshot.restoring',
                               name: env[:snapshot_name])
          env[:machine].provider.driver.restore_snapshot(
            env[:machine].id, snapshot_id)

          @app.call(env)
        end
      end
    end
  end
end
