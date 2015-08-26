require 'vagrant/util/template_renderer'

module VagrantPlugins
  module Parallels
    module Action
      class PackageConfigFiles
        # For TemplateRenderer
        include Vagrant::Util

        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env
          create_metadata
          @app.call(env)
        end

        def create_metadata
          File.open(File.join(@env['export.temp_dir'], 'metadata.json'), 'w') do |f|
            f.write(template_metadatafile)
          end
        end

        private

        def template_metadatafile
          %Q({"provider": "parallels"}\n)
        end
      end
    end
  end
end
