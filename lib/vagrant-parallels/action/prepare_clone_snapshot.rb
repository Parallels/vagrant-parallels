require 'log4r'

require 'digest/md5'

module VagrantPlugins
  module Parallels
    module Action
      class PrepareCloneSnapshot
        @@lock = Mutex.new

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::prepare_clone_snapshot')
        end

        def call(env)
          if !env[:clone_id]
            @logger.info('No source VM for cloning, skip snapshot preparing')
            return @app.call(env)
          end

          if Util::Common::is_macvm(env[:machine])
            #Ignore, since macvms doesn't support snapshot creation
            @logger.info('Snapshot creation is not supported yet for macOS ARM Guests, skip snapshot preparing')
            return @app.call(env)
          end

          # If we're not doing a linked clone, snapshots don't matter
          if !env[:machine].provider_config.linked_clone
            return @app.call(env)
          end

          # We lock so that we don't snapshot in parallel
          @@lock.synchronize do
            lock_key = Digest::MD5.hexdigest("#{env[:clone_id]}-snapshot")
            env[:machine].env.lock(lock_key, retry: true) do
              prepare_snapshot(env)
            end
          end

          # Continue
          @app.call(env)
        end

        protected

        def prepare_snapshot(env)
          set_snapshot = env[:machine].provider_config.linked_clone_snapshot
          env[:clone_snapshot] = set_snapshot || 'vagrant_linked_clone'

          # Get the snapshots. We're done if it already exists
          snapshots = env[:machine].provider.driver.list_snapshots(env[:clone_id])

          if snapshots.include?(env[:clone_snapshot])
            env[:clone_snapshot_id] = snapshots[env[:clone_snapshot]]
            @logger.info('Linked clone snapshot already exists, doing nothing')
            return
          end

          # We've specified the snapshot name but it doesn't exist
          if set_snapshot
            raise Errors::SnapshotNotFound, snapshot: set_snapshot
          end

          @logger.info('Creating a new snapshot for linked clone')
          env[:clone_snapshot_id] = env[:machine].provider.driver.create_snapshot(
            env[:clone_id], env[:clone_snapshot])
        end
      end
    end
  end
end
