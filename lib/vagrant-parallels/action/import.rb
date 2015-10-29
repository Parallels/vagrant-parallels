require 'nokogiri'

module VagrantPlugins
  module Parallels
    module Action
      class Import
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::import')
        end

        def call(env)
          @machine = env[:machine]

          # Disable requiring password for register and clone actions [GH-67].
          # It is available only since PD 10.
          if env[:machine].provider.pd_version_satisfies?('>= 10')
            acts = ['clone-vm']
            @logger.info("Disabling password restrictions: #{acts.join(', ')}")
            env[:machine].provider.driver.disable_password_restrictions(acts)
          end

          # Import VM, e.q. clone it from registered template
          import(env)

          # Flag as erroneous and return if import failed
          raise Errors::VMImportFailure if !@machine.id

          # Import completed successfully. Continue the chain
          @app.call(env)
        end

        def recover(env)
          if @machine.state.id != :not_created
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

        def import(env)
          # Linked clones are supported only for PD 11 and higher
          if @machine.provider_config.linked_clone \
            && @machine.provider.pd_version_satisfies?('>= 11')

            env[:ui].info I18n.t('vagrant_parallels.actions.vm.import.importing_linked',
                                 :name => @machine.box.name)
            opts = {
              snapshot_id: snapshot_id(env[:clone_id]),
              linked: true
            }
            # Linked clone creation should not be concurrent [GH-206]
            begin
              @machine.env.lock("parallels_linked_clone") do
                clone(env, opts)
              end
            rescue Vagrant::Errors::EnvironmentLockedError
              sleep 1
              retry
            end
          else
            env[:ui].info I18n.t('vagrant.actions.vm.import.importing',
                                 :name => @machine.box.name)
            clone(env)
          end

          if @machine.provider_config.regen_src_uuid
            @logger.info('Regenerate SourceVmUuid')
            @machine.provider.driver.regenerate_src_uuid
          end

          # Remove 'Icon\r' file from VM home (bug in PD 11.0.0)
          if @machine.provider.pd_version_satisfies?('= 11.0.0')
            vm_home = @machine.provider.driver.read_settings.fetch('Home')
            broken_icns = Dir[File.join(vm_home, 'Icon*')]
            FileUtils.rm(broken_icns, :force => true)
          end
        end

        def clone(env, opts={})
          # Generate virtual machine name
          vm_name = "vagrant_vm_#{(Time.now.to_f * 1000.0).to_i}_#{rand(100000)}"

          @machine.id = @machine.provider.driver.clone_vm(env[:clone_id], vm_name, opts) do |progress|
            env[:ui].clear_line
            env[:ui].report_progress(progress, 100, false)

            # # If we got interrupted, then the import could have been interrupted.
            # Just rise an exception and then 'recover' will be called to cleanup.
            raise Vagrant::Errors::VagrantInterrupt if env[:interrupted]
          end

          # Clear the line one last time since the progress meter doesn't disappear
          # immediately.
          env[:ui].clear_line
        end

        def snapshot_id(vm_uuid)
          snap_id = @machine.provider.driver.read_current_snapshot(vm_uuid)

          # If there is no current snapshot, just create the new one.
          if !snap_id
            @logger.info('Create a new snapshot')
            opts = {
              name: 'vagrant_linked_clone',
              desc: 'Snapshot to create linked clones for Vagrant'
            }
            snap_id = @machine.provider.driver.create_snapshot(vm_uuid, opts)
          end

          @logger.info("User this snapshot ID to create a linked clone: #{snap_id}")
          snap_id
        end

      end
    end
  end
end
