require 'shellwords'

require_relative "../../util/unix_mount_helpers"

module VagrantPlugins
  module Parallels
    module GuestLinuxCap
      class MountParallelsSharedFolder
        extend VagrantPlugins::Parallels::Util::UnixMountHelpers

        # Mounts Parallels Desktop shared folder on linux guest
        #
        # @param [Machine] machine
        # @param [String] name of mount
        # @param [String] path of mount on guest
        # @param [Hash] hash of mount options
        def self.mount_parallels_shared_folder(machine, name, guestpath, options)
          # Sanity check for mount options: we are not supporting
          # VirtualBox-specific 'fmode' and 'dmode' options
          if options[:mount_options]
            invalid_opts = options[:mount_options].select do |opt|
              opt =~ /^(d|f)mode/
            end

            if !invalid_opts.empty?
              raise Errors::LinuxPrlFsInvalidOptions, options: invalid_opts
            end
          end

          guest_path = Shellwords.escape(guestpath)
          mount_type = options[:plugin].capability(:mount_type)

          @@logger.debug("Mounting #{name} (#{options[:hostpath]} to #{guestpath})")

          mount_options, mount_uid, mount_gid = options[:plugin].capability(:mount_options, name, guest_path, options)
          # In Parallels 20.2.0, prl_fs is removed and shares stop working with the
          # `mount` command.  Using prl_fsd fixes this issue.

          # prl_fsd does not support the _netdev option, so we need to remove it from the mount options
          # for supported mount_options check prl_fsd --help in guest machine after installing Parallels Tools
          
          # the `share` option needs to be passed as an extra `--share` argument

          prl_fsd_mount_options = mount_options.split(',').reject { |opt| opt == '_netdev' }

          # The `big_writes` mount option was removed in libfuse3 (guests that
          # ship `fusermount3`, e.g. Ubuntu 24.04+), since big writes have been
          # negotiated automatically via the FUSE_BIG_WRITES capability since
          # Linux kernel 2.6.26. Passing it on a libfuse3 guest causes prl_fsd
          # to fail outright with:
          #   fuse: unknown option(s): `-o big_writes'
          # On libfuse2 guests (only `fusermount`, no `fusermount3` binary) the
          # option is still the way to opt in to larger write sizes, so keep
          # passing it there for backwards compatibility (e.g. Ubuntu 18.04).
          uses_fuse3 = machine.communicate.test("command -v fusermount3")
          prl_fsd_mount_options << "big_writes" unless uses_fuse3
          prl_fsd_mount_options << "fsname=#{name}"
          prl_fsd_mount_options << "subtype=prl_fsd"

          if mount_options.include?('share')
            share_flag = '--share'
            prl_fsd_mount_options.reject! { |opt| opt == 'share' || opt.start_with?('uid=', 'gid=') }
          else
            share_flag = ''
          end

          o_options = prl_fsd_mount_options.join(',')

          mount_command = <<-CMD
            if [ -f /usr/bin/prl_fsd ]; then
              prl_fsd #{guest_path} -o #{o_options} #{share_flag} --sf=#{name}
            else
              mount -t #{mount_type} -o #{mount_options} #{name} #{guest_path}
            fi
          CMD

          # Create the guest path if it doesn't exist
          machine.communicate.sudo("mkdir -p #{guest_path}")

          # On Ubuntu 26.04+, AppArmor's fusermount3 profile blocks FUSE mounts by default.
          # Add an override rule for this mountpoint and reload the profile.
          # AppArmor requires a trailing slash on directory paths in mount rules.
          apparmor_mountpoint = guestpath.end_with?('/') ? guestpath : "#{guestpath}/"
          apparmor_setup = <<-CMD
            if [ -f /usr/bin/prl_fsd ] && [ -f /etc/apparmor.d/fusermount3 ]; then
              mkdir -p /etc/apparmor.d/local
              rule="mount fstype=@{fuse_types} -> #{apparmor_mountpoint},"
              grep -qF "$rule" /etc/apparmor.d/local/fusermount3 2>/dev/null || echo "$rule" >> /etc/apparmor.d/local/fusermount3
              apparmor_parser -r /etc/apparmor.d/fusermount3
            fi
          CMD
          machine.communicate.sudo(apparmor_setup)

          # Attempt to mount the folder. We retry here a few times because
          # it can fail early on.
          stderr = ""
          retryable(on: Errors::ParallelsMountFailed, tries: 3, sleep: 5) do
            machine.communicate.sudo(mount_command,
              error_class: Errors::ParallelsMountFailed,
              error_key: :parallels_mount_failed,
              command: mount_command,
              output: stderr,
            ) { |type, data| stderr = data if type == :stderr }
          end

          emit_upstart_notification(machine, guest_path)
        end

        def self.unmount_parallels_shared_folder(machine, guestpath, options)
          guest_path = Shellwords.escape(guestpath)

          result = machine.communicate.sudo("umount #{guest_path}", error_check: false)
          if result == 0
            machine.communicate.sudo("rmdir #{guest_path}", error_check: false)
          end
        end

        def self.prepare_psf_services(machine)
          # Parallels Tools for Linux includes native auto-mount script,
          # which causes loosing some of Vagrant-relative shared folders.
          # So, we should to disable this behavior. [GH-102]

          auto_mount_script = '/usr/bin/prlfsmountd'
          if machine.communicate.test("test -f #{auto_mount_script}")
            machine.communicate.sudo(
              "echo -e '#!/bin/sh\n'" +
                '# Shared folders auto-mount is disabled by Vagrant ' +
                "> #{auto_mount_script}")
          end
        end
      end
    end
  end
end
