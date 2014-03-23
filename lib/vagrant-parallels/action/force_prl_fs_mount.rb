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
        end

        def call(env)
          # Only for Linux guests!
          if env[:machine].communicate.test("uname -s | grep 'Linux'")
            folders = synced_folders(env[:machine])[:parallels]
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
