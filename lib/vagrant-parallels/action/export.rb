require "fileutils"

module VagrantPlugins
  module Parallels
    module Action
      class Export
        attr_reader :temp_dir

        include Util

        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          raise Vagrant::Errors::VMPowerOffToPackage if \
            @env[:machine].provider.state.id != :stopped

          setup_temp_dir
          export

          @app.call(env)

          recover(env) # called to cleanup temp directory
        end

        def recover(env)
          if temp_dir && File.exist?(temp_dir)
            FileUtils.rm_rf(temp_dir)
          end
        end

        def setup_temp_dir
          @env[:ui].info I18n.t("vagrant.actions.vm.export.create_dir")
          @temp_dir = @env["export.temp_dir"] = @env[:tmp_path].join(Time.now.to_i.to_s)
          FileUtils.mkpath(@env["export.temp_dir"])
        end

        def export

          vm_name = generate_name(@env[:root_path], 'cloned')

          @env[:ui].info I18n.t("vagrant.actions.vm.export.exporting")
          uuid = @env[:machine].provider.driver.export(@env["export.temp_dir"], vm_name) do |progress|
            @env[:ui].clear_line
            @env[:ui].report_progress(progress, 100, false)
          end
          @env[:ui].clear_line

          @env[:ui].info I18n.t("vagrant.actions.vm.export.compacting")
          @env[:machine].provider.driver.compact(uuid) do |progress|
            @env[:ui].clear_line
            @env[:ui].report_progress(progress, 100, false)
          end
          @env[:machine].provider.driver.unregister(uuid)

          # Clear the line a final time so the next data can appear
          # alone on the line.
          @env[:ui].clear_line
        end
      end
    end
  end
end
