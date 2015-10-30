require 'log4r'

require 'digest/md5'

module VagrantPlugins
  module Parallels
    module Action
      class PrepareCloneSnapshot
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::prepare_clone_snapshot')
        end

        def call(env)
          if !env[:clone_id]
            @logger.info('No source VM for cloning, skip snapshot preparing')
            return @app.call(env)
          end

          # If we're not doing a linked clone, snapshots don't matter
          if !env[:machine].provider_config.linked_clone \
            || env[:machine].provider.pd_version_satisfies?('< 11')
            return @app.call(env)
          end

          # We lock so that we don't snapshot in parallel
          lock_key = Digest::MD5.hexdigest("#{env[:clone_id]}-snapshot")
          env[:machine].env.lock(lock_key, retry: true) do
            prepare_snapshot(env)
          end

          # Continue
          @app.call(env)
        end

        protected

        def prepare_snapshot(env)
          set_snapshot = env[:machine].provider_config.linked_clone_snapshot

          if set_snapshot
            # Get the snapshots. We're done if it already exists
            snapshots = env[:machine].provider.driver.list_snapshots(env[:clone_id])

            if !snapshots.include?(set_snapshot)
              raise Errors::SnapshotNotFound, snapshot: set_snapshot
            end

            @logger.info('Specified snapshot already exists, doing nothing')
            env[:clone_snapshot] = set_snapshot
            return
          end

          # Get the current snapshot. If exist - use it for linked clone
          curr_snapshot = env[:machine].provider.driver.read_current_snapshot(env[:clone_id])
          if curr_snapshot
            @logger.info("The source VM already has a snapshot, use it: #{curr_snapshot}")
            env[:clone_snapshot] = curr_snapshot
            return
          end

          opts = {
            name: 'vagrant_linked_clone',
            desc: 'Snapshot to create linked clones for Vagrant'
          }
          @logger.info('Creating a new snapshot for linked clone')
          new_snap_id = env[:machine].provider.driver.create_snapshot(
            env[:clone_id], opts) do |progress|
              env[:ui].clear_line
              env[:ui].report_progress(progress, 100, false)
          end

          env[:clone_snapshot] = new_snap_id
        end
      end
    end
  end
end
