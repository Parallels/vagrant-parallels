require 'nokogiri'

require 'digest/md5'

module VagrantPlugins
  module Parallels
    module Action
      class Import
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::import')
        end

        def call(env)
          # Disable requiring password for register and clone actions [GH-67].
          # It is available only since PD 10.
          if env[:machine].provider.pd_version_satisfies?('>= 10')
            acts = ['clone-vm']
            @logger.info("Disabling password restrictions: #{acts.join(', ')}")
            env[:machine].provider.driver.disable_password_restrictions(acts)
          end

          # Linked clones are supported only for PD 11 and higher
          if env[:machine].provider_config.linked_clone \
            && env[:machine].provider.pd_version_satisfies?('>= 11')
            # Linked clone creation should not be concurrent [GH-206]
            lock_key = Digest::MD5.hexdigest("#{env[:clone_id]}-linked-clone")
            env[:machine].env.lock(lock_key, retry: true) do
              clone_linked(env)
            end
          else
            clone_full(env)
          end

          # If we got interrupted, then the import could have been
          # interrupted and its not a big deal. Just return out.
          return if env[:interrupted]

          # Flag as erroneous and return if import failed
          raise Errors::VMCloneFailure if !env[:machine].id

          if env[:machine].provider_config.regen_src_uuid \
            && env[:machine].provider.pd_version_satisfies?('< 11')
            @logger.info('Regenerate SourceVmUuid by editing config.pvs file')
            env[:machine].provider.driver.regenerate_src_uuid
          end

          # Remove 'Icon\r' file from VM home (bug in PD 11.0.0)
          if env[:machine].provider.pd_version_satisfies?('= 11.0.0')
            vm_home = env[:machine].provider.driver.read_settings.fetch('Home')
            broken_icns = Dir[File.join(vm_home, 'Icon*')]
            FileUtils.rm(broken_icns, :force => true)
          end

          # Copy the SSH key from the clone machine if we can
          if env[:clone_machine]
            key_path = env[:clone_machine].data_dir.join('private_key')
            if key_path.file?
              FileUtils.cp(key_path, env[:machine].data_dir.join('private_key'))
            end
          end

          # Import completed successfully. Continue the chain
          @app.call(env)
        end

        def recover(env)
          if env[:machine] && env[:machine].state.id != :not_created
            return if env['vagrant.error'].is_a?(Vagrant::Errors::VagrantError)
            return if env['vagrant_parallels.error'].is_a?(Errors::VagrantParallelsError)

            # If we're not supposed to destroy on error then just return
            return if !env[:destroy_on_error]

            # Interrupted, destroy the VM. We note that we don't want to
            # validate the configuration here, and we don't want to confirm
            # we want to destroy.
            destroy_env = env.clone
            destroy_env[:config_validate] = false
            destroy_env[:force_confirm_destroy] = true
            env[:action_runner].run(Action.action_destroy, destroy_env)
          end
        end

        protected

        def clone_full(env)
          env[:ui].info I18n.t('vagrant_parallels.actions.vm.clone.full')
          env[:machine].id = env[:machine].provider.driver.clone_vm(
            env[:clone_id]) do |progress|
            env[:ui].clear_line
            env[:ui].report_progress(progress, 100, false)
          end

          # Clear the line one last time since the progress meter doesn't disappear
          # immediately.
          env[:ui].clear_line
        end

        def clone_linked(env)
          opts = {
            snapshot_id: env[:clone_snapshot],
            linked: true
          }
          env[:ui].info I18n.t('vagrant_parallels.actions.vm.clone.linked')
          env[:machine].id = env[:machine].provider.driver.clone_vm(
            env[:clone_id], opts) do |progress|
            env[:ui].clear_line
            env[:ui].report_progress(progress, 100, false)
          end

          # Clear the line one last time since the progress meter doesn't disappear
          # immediately.
          env[:ui].clear_line
        end
      end
    end
  end
end
