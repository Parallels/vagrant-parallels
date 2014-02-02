module VagrantPlugins
  module Parallels
    module Action
      class Export
        include Util

        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          raise Vagrant::Errors::VMPowerOffToPackage if \
            @env[:machine].provider.state.id != :stopped

          export
          compact

          @app.call(env)
        end

        def export
          temp_vm_name = generate_name(@env[:root_path], '_export')

          @env[:ui].info I18n.t("vagrant.actions.vm.export.exporting")
          @temp_vm_uuid = @env[:machine].provider.driver.export(@env["export.temp_dir"], temp_vm_name) do |progress|
            @env[:ui].clear_line
            @env[:ui].report_progress(progress, 100, false)
          end

          # Clear the line a final time so the next data can appear
          # alone on the line.
          @env[:ui].clear_line
        end

        def compact
          @env[:ui].info I18n.t("vagrant_parallels.actions.vm.export.compacting")
          @env[:machine].provider.driver.compact(@temp_vm_uuid) do |progress|
            @env[:ui].clear_line
            @env[:ui].report_progress(progress, 100, false)
          end
          @env[:machine].provider.driver.unregister(@temp_vm_uuid)

          # Clear the line a final time so the next data can appear
          # alone on the line.
          @env[:ui].clear_line
        end
      end
    end
  end
end
