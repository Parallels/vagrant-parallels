require "log4r"
require 'vagrant/util/platform'

module VagrantPlugins
  module Parallels
    module Action
      class ForcePrlFsMount
        # This middleware forces the prl_fs mount after the Resume, because
        # there is bug in Linux guests - custom shared folders are missed after
        # the resume [GH-102]
        include Vagrant::Action::Builtin::MixinSyncedFolders

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::plugins::parallels::force_prl_fs_mount")
        end

        def call(env)
          # Only for Linux guests!
          if env[:machine].communicate.test("uname -s | grep 'Linux'")
            folders = synced_folders(env[:machine])[:parallels]

            # Go through each folder and make sure to create it if
            # it does not exist on host
            folders.each do |id, data|
              data[:hostpath] = File.expand_path(data[:hostpath], env[:root_path])

              # Create the hostpath if it doesn't exist and we've been told to
              if !File.directory?(data[:hostpath]) && data[:create]
                @logger.info("Creating shared folder host directory: #{data[:hostpath]}")
                begin
                  Pathname.new(data[:hostpath]).mkpath
                rescue Errno::EACCES
                  raise Vagrant::Errors::SharedFolderCreateFailed,
                        path: data[:hostpath]
                end
              end

              if File.directory?(data[:hostpath])
                data[:hostpath] = File.realpath(data[:hostpath])
                data[:hostpath] = Vagrant::Util::Platform.fs_real_path(data[:hostpath]).to_s
              end
            end

            opts = nil
            instance = VagrantPlugins::Parallels::SyncedFolder.new
            instance.enable(env[:machine], folders, opts)
          end

          @app.call(env)
        end
      end
    end
  end
end
