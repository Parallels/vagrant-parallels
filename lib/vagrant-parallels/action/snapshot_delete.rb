module VagrantPlugins
  module Parallels
    module Action
      class SnapshotDelete
        def initialize(app, env)
          @app = app
        end

        def call(env)
          snapshots = env[:machine].provider.driver.list_snapshots(env[:machine].id)
          snapshot_id = snapshots[env[:snapshot_name]]

          env[:ui].info I18n.t('vagrant.actions.vm.snapshot.deleting',
                               name: env[:snapshot_name])
          env[:machine].provider.driver.delete_snapshot(
            env[:machine].id, snapshot_id)

          env[:ui].success I18n.t('vagrant.actions.vm.snapshot.deleted',
                                  name: env[:snapshot_name])
          @app.call(env)
        end
      end
    end
  end
end
