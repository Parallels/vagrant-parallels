require "pathname"

require "log4r"

require "vagrant/util/platform"
require "vagrant/util/scoped_hash_override"

module VagrantPlugins
  module Parallels
    module Action
      class ShareFolders
        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::action::vm::share_folders")
          @app    = app
        end

        def call(env)
          @env = env

          prepare_folders
          create_metadata

          @app.call(env)

          mount_shared_folders
        end

        # This method returns an actual list of Parallels Desktop
        # shared folders to create and their proper path.
        def shared_folders
          {}.tap do |result|
            @env[:machine].config.vm.synced_folders.each do |id, data|
              data = scoped_hash_override(data, :parallels)

              # Ignore NFS shared folders
              next if data[:nfs]

              # Ignore disabled shared folders
              next if data[:disabled]

              # This to prevent overwriting the actual shared folders data
              id = Pathname.new(id).to_s.split('/').drop_while{|i| i.empty?}.join('_')
              result[id] = data.dup
            end
          end
        end

        # Prepares the shared folders by verifying they exist and creating them
        # if they don't.
        def prepare_folders
          shared_folders.each do |id, options|
            hostpath = Pathname.new(options[:hostpath]).expand_path(@env[:root_path])

            if !hostpath.directory? && options[:create]
              # Host path doesn't exist, so let's create it.
              @logger.debug("Host path doesn't exist, creating: #{hostpath}")

              begin
                hostpath.mkpath
              rescue Errno::EACCES
                raise Vagrant::Errors::SharedFolderCreateFailed,
                  :path => hostpath.to_s
              end
            end
          end
        end

        def create_metadata
          @env[:ui].info I18n.t("vagrant.actions.vm.share_folders.creating")

          folders = []
          shared_folders.each do |id, data|
            hostpath = File.expand_path(data[:hostpath], @env[:root_path])
            hostpath = Vagrant::Util::Platform.cygwin_windows_path(hostpath)

            folders << {
              :name => id,
              :hostpath => hostpath,
              :transient => data[:transient]
            }
          end

          @env[:machine].provider.driver.share_folders(folders)
        end

        # TODO: Fix this, doesn't execute at the correct time
        def mount_shared_folders
          @env[:ui].info I18n.t("vagrant.actions.vm.share_folders.mounting")

          # short guestpaths first, so we don't step on ourselves
          folders = shared_folders.sort_by do |id, data|
            if data[:guestpath]
              data[:guestpath].length
            else
              # A long enough path to just do this at the end.
              10000
            end
          end

          # Go through each folder and mount
          folders.each do |id, data|
            if data[:guestpath]
              # Guest path specified, so mount the folder to specified point
              @env[:ui].info(I18n.t("vagrant.actions.vm.share_folders.mounting_entry",
                                    :guest_path => data[:guestpath]))

              # Dup the data so we can pass it to the guest API
              data = data.dup

              # Calculate the owner and group
              ssh_info = @env[:machine].ssh_info
              data[:owner] ||= ssh_info[:username]
              data[:group] ||= ssh_info[:username]

              # Mount the actual folder
              @env[:machine].guest.capability(
                :mount_parallels_shared_folder, id, data[:guestpath], data)
            else
              # If no guest path is specified, then automounting is disabled
              @env[:ui].info(I18n.t("vagrant.actions.vm.share_folders.nomount_entry",
                                    :host_path => data[:hostpath]))
            end
          end
        end
      end
    end
  end
end
