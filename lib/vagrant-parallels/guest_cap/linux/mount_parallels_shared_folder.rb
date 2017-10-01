module VagrantPlugins
  module Parallels
    module GuestLinuxCap
      class MountParallelsSharedFolder
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

          expanded_guest_path = machine.guest.capability(
            :shell_expand_guest_path, guestpath)

          mount_commands = []

          if options[:owner].is_a? Integer
            mount_uid = options[:owner]
          else
            mount_uid = "`id -u #{options[:owner]}`"
          end

          if options[:group].is_a? Integer
            mount_gid = options[:group]
            mount_gid_old = options[:group]
          else
            mount_gid = "`getent group #{options[:group]} | cut -d: -f3`"
            mount_gid_old = "`id -g #{options[:group]}`"
          end

          # First mount command uses getent to get the group
          mount_options = "-o uid=#{mount_uid},gid=#{mount_gid}"
          mount_options += ",#{options[:mount_options].join(',')}" if options[:mount_options]
          mount_commands << "mount -t prl_fs #{mount_options} #{name} #{expanded_guest_path}"

          # Second mount command uses the old style `id -g`
          mount_options = "-o uid=#{mount_uid},gid=#{mount_gid_old}"
          mount_options += ",#{options[:mount_options].join(',')}" if options[:mount_options]
          mount_commands << "mount -t prl_fs #{mount_options} #{name} #{expanded_guest_path}"

          # Clear prior symlink if exists
          if machine.communicate.test("test -L #{expanded_guest_path}")
            machine.communicate.sudo("rm #{expanded_guest_path}")
          end

          # Create the guest path if it doesn't exist
          machine.communicate.sudo("mkdir -p #{expanded_guest_path}")

          # Attempt to mount the folder. We retry here a few times because
          # it can fail early on.
          attempts = 0
          while true
            success = true

            mount_commands.each do |command|
              no_such_device = false
              status = machine.communicate.sudo(command, error_check: false) do |type, data|
                no_such_device = true if type == :stderr && data =~ /No such device/i
              end

              success = status == 0 && !no_such_device
              break if success
            end

            break if success

            attempts += 1
            if attempts > 10
              raise VagrantPlugins::Parallels::Errors::LinuxMountFailed,
                command: mount_commands.join("\n")
            end

            sleep 2
          end

          # Emit an upstart event if we can
          machine.communicate.sudo <<-EOH.gsub(/^ {10}/, "")
            if command -v /sbin/init && /sbin/init 2>/dev/null --version | grep upstart; then
              /sbin/initctl emit --no-wait vagrant-mounted MOUNTPOINT=#{expanded_guest_path}
            fi
          EOH
        end

        def self.unmount_parallels_shared_folder(machine, guestpath, options)
          result = machine.communicate.sudo(
            "umount #{guestpath}", error_check: false)
          if result == 0
            machine.communicate.sudo("rmdir #{guestpath}", error_check: false)
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
