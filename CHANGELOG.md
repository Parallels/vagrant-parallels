## 2.4.2 (Feb 5, 2024)

BUG FIXES:
  - Revert "use clonefile copy for macvm boxes"
  [[GH-464](https://github.com/Parallels/vagrant-parallels/pull/464)]
## 2.4.1 (Oct 16, 2023)
IMPROVEMENTS:
  - use clonefile copy for macvm boxes
  [[GH-459](https://github.com/Parallels/vagrant-parallels/pull/459)]

BUG FIXES:
  - Bump activesupport from 6.1.7.3 to 6.1.7.5
  [[GH-457](https://github.com/Parallels/vagrant-parallels/pull/457)]
  - Don't try to call methdods on Nil
  [[GH-456](https://github.com/Parallels/vagrant-parallels/pull/456)]
  - Add a doc note for releasing a new provider version
  [[GH-452](https://github.com/Parallels/vagrant-parallels/pull/452)]
  - website: Remove unused images
  [[GH-450](https://github.com/Parallels/vagrant-parallels/pull/450)]
  - adding macos
  [[GH-447](https://github.com/Parallels/vagrant-parallels/pull/447)]

## 2.4.0 (May 22, 2023)
IMPROVEMENTS:
  - Implement shared folder support for `.macvm` VMs
  [[GH-448](https://github.com/Parallels/vagrant-parallels/pull/448)]

BUG FIXES:
  - Fix shared folder mount error on `.macvm` VMs
  [[GH-445](https://github.com/Parallels/vagrant-parallels/pull/445)]

## 2.3.1 (March 23, 2023)
BUG FIXES:
  - Fix the detection of VM IP. Wait for the IP to become available to
  avoid connection issues and Vagrant warnings.
  [[GH-440](https://github.com/Parallels/vagrant-parallels/issues/440)]

## 2.3.0 (March 22, 2023)
IMPROVEMENTS:
  - Support fetching the VM IP using prlctl
  [[GH-434](https://github.com/Parallels/vagrant-parallels/pull/434)].
  - Update gem dependensies and support Ruby 3.0
  [[GH-437](https://github.com/Parallels/vagrant-parallels/pull/437)],
  [[GH-439](https://github.com/Parallels/vagrant-parallels/pull/439)].

BUG FIXES:
  - Fixes SSH access to `.macvm` VMs on Macs with Apple M-series chip
  [[GH-435](https://github.com/Parallels/vagrant-parallels/issues/435)]

## 2.2.6 (December 19, 2022)
BUG FIXES:
  - Fix the macOS VMs support on ARM-based Mac
  [[GH-429](https://github.com/Parallels/vagrant-parallels/pull/429)]

## 2.2.5 (February 22, 2022)
BUG FIXES:
  - Fixed Parallels Tool installation on M1 hosts with arm64
  [[GH-416](https://github.com/Parallels/vagrant-parallels/pull/416)]

## 2.2.4 (August 18, 2021)
BUG FIXES:
  - Fixed running the provisioner on "vagrant up --provision"
  [[GH-402](https://github.com/Parallels/vagrant-parallels/pull/402)]

## 2.2.3 (July 14, 2021)
BUG FIXES:
  - Fixed the compatibility with Vagrant 2.2.17
  [[GH-399](https://github.com/Parallels/vagrant-parallels/pull/399)]

## 2.2.2 (June 23, 2021)
BUG FIXES:
  - Fixed shared folder mount on the VM reboot
  [[GH-391](https://github.com/Parallels/vagrant-parallels/pull/391)]

## 2.2.1 (April 14, 2021)
BUG FIXES:
  - Fixed the compatibility with Vagrant 2.2.15
  [[GH-386](https://github.com/Parallels/vagrant-parallels/pull/386)]

## 2.2.0 (March 3, 2021)
IMPROVEMENTS:
  - Mount shared folders after manual VM reboot
  [[GH-377](https://github.com/Parallels/vagrant-parallels/pull/377)]

BUG FIXES:
  - Fixed mount of shared folders with non-ASCII symbols in the name
  [[GH-290](https://github.com/Parallels/vagrant-parallels/issues/290)]

## 2.1.0 (November 25, 2020)
BUG FIXES:
  - Fixed the private network adapter workflow on macOS 11.0 Big Sur
  [[GH-371](https://github.com/Parallels/vagrant-parallels/pull/371)]
  - Fixed the concurrency issue with box unregister in multi-vm environment
  [[GH-370](https://github.com/Parallels/vagrant-parallels/pull/370)]
  - Fixed the `vagrant package` with custom `Vagrantfile`
  [[GH-368](https://github.com/Parallels/vagrant-parallels/pull/368)]

## 2.0.1 (April 23, 2019)
BUG FIXES:
  - Fixed the error message for host-only network collision
  [[GH-340](https://github.com/Parallels/vagrant-parallels/issues/340)]

## 2.0.0 (November 19, 2018)
BREAKING CHANGES:
  - **Linked Clone feature is enabled by default.**
  Now each time when you create a new virtual machine with `vagrant up` it is
  created as a linked clone of the box image (instead of the full clone, as it
  was before). Read more about it:
  [Full Clone vs Linked Clone](https://parallels.github.io/vagrant-parallels/docs/configuration.html#linked_clone).
  - **Dropped support of Parallels Desktop 10**. It reached
  [End-of-Life and End-of-Support](https://kb.parallels.com/eu/122533).

## 1.7.8 (November 18, 2017)
BUG FIXES:
  - Fixed warning messages with Vagrant v2.0.1
  [[GH-311](https://github.com/Parallels/vagrant-parallels/issues/311)]

## 1.7.7 (October 15, 2017)
BUG FIXES:
  - Fixed synced folder mounting on guests with Upstart (Ubuntu 14.*)
  [[GH-307](https://github.com/Parallels/vagrant-parallels/issues/307)]


## 1.7.6 (July 31, 2017)
BUG FIXES:
  - Fixed `vagrant up` failure if the box image was automatically renamed due
  to the name conflict.
  [[GH-303](https://github.com/Parallels/vagrant-parallels/issues/303)]


## 1.7.5 (May 27, 2017)
BUG FIXES:
  - Fixed compatibility with Vagrant v1.9.5+. `nokogiri` gem is defined as
  a plugin runtime dependency.
  [[GH-297](https://github.com/Parallels/vagrant-parallels/issues/297)],
  [[GH-298](https://github.com/Parallels/vagrant-parallels/pull/298)]

  **NB!** To use the plugin with Vagrant v1.9.5 you should (re)install it with
  `NOKOGIRI_USE_SYSTEM_LIBRARIES` enabled:
  ```bash
  $ vagrant plugin uninstall vagrant-parallels
  $ NOKOGIRI_USE_SYSTEM_LIBRARIES=true vagrant plugin install vagrant-parallels
  ```


## 1.7.4 (April 20, 2017)
IMPROVEMENTS:
  - Make start action (`"vagrant up"`) run provisioners if VM is running.
  [[GH-294](https://github.com/Parallels/vagrant-parallels/pull/294)]

BUG FIXES:
  - Properly handle `"paused"` VM state for up and halt actions.
  [[GH-295](https://github.com/Parallels/vagrant-parallels/pull/295)]
  - synced_folder: Escape special characters in Windows-specific guest paths.
  [[GH-296](https://github.com/Parallels/vagrant-parallels/pull/296)]


## 1.7.3 (February 28, 2017)
BUG FIXES:
  - Fix exceptions related to `nokogiri` gem.
  [[GH-291](https://github.com/Parallels/vagrant-parallels/issues/291)],
  [[GH-292](https://github.com/Parallels/vagrant-parallels/issues/292)]


## 1.7.2 (December 16, 2016)
BUG FIXES:
  - Fix Parallels Tools update in Linux guests. Call `ptiagent-cmd` with `--install`,
  not `--info`. [[GH-286](https://github.com/Parallels/vagrant-parallels/pull/286)]


## 1.7.1 (December 7, 2016)
FEATURES:
  - **Guest capability for installing Parallels Tools in Windows.** Now it is
  possible to install/upgrade Parallels Tools in Windows guests using
  the provider option `update_guest_tools`. [[GH-284](https://github.com/Parallels/vagrant-parallels/pull/284)]

BUG FIXES:
  - Fix issues of auto-updating Parallels Tools in Linux guests with Parallels Desktop 12+.
  [[GH-283](https://github.com/Parallels/vagrant-parallels/pull/283)],
  [[GH-282](https://github.com/Parallels/vagrant-parallels/pull/282)],
  [[GH-281](https://github.com/Parallels/vagrant-parallels/pull/281)]


## 1.7.0 (November 15, 2016)
BREAKING CHANGES:
  - **Dropped support of Parallels Desktop 8 and 9**. These versions have
  reached their [End-of-Life and End-of-Support](https://kb.parallels.com/eu/122533).
  - **Removed customization options, which were previously deprecated:** [[GH-271](https://github.com/Parallels/vagrant-parallels/pull/271)]
    - "use_linked_clone" - use `linked_clone` instead.
    - "regen_box_uuid" - use `regen_src_uuid` instead.
    - "optimize_power_consumption".

FEATURES:
  - **IPv6 Private Networks:** Private networking now supports IPv6.
  This only works with Parallels Desktop 12 and higher.
  [[GH-273](https://github.com/Parallels/vagrant-parallels/pull/273)]


## 1.6.3 (July 11, 2016)
DEPRECATIONS:
  - The following provider options were renamed:
    - `regen_box_uuid` was renamed to `regen_src_uuid`
    - `use_linked_clone` was renamed to `linked clone`

  Old names are still supported, but will be removed in `vagrant-parallels` v1.7.0.
  [[GH-260](https://github.com/Parallels/vagrant-parallels/pull/260)]

IMPROVEMENTS:
  - Allow to package linked clones with `vagrant package`. External disk images
  will be automatically copied, so the resulted box become a full-sized
  standalone VM. [[GH-262](https://github.com/Parallels/vagrant-parallels/pull/262)]
  - Handle the situation when host machine is not connected to Shared network.
  With Parallels Desktop 11.2.1+ Vagrant will connect it automatically. With earlier
  versions, the human-readable error message will be displayed.
  [[GH-266](https://github.com/Parallels/vagrant-parallels/pull/266)]
  - Disable home folder sharing by default (Parallels Desktop 11+).
  [[GH-257](https://github.com/Parallels/vagrant-parallels/pull/257)]

BUG FIXES:
  - action/box_unregister: Fix `#recover` method  for layered environments.
  [[GH-261](https://github.com/Parallels/vagrant-parallels/pull/261)]
  - action/network: Fix an exception when option "Connect Mac to
  this network" is disabled. [[GH-268](https://github.com/Parallels/vagrant-parallels/pull/268)]
  - commands/snapshot: Add retries for snapshot commands to avoid `prlctl`
  failures. [[GH-259](https://github.com/Parallels/vagrant-parallels/pull/259)]


## 1.6.2 (March 23, 2016)
BUG FIXES:
  - Fix unsupported action error for `vagrant snapshot` commands [[GH-254](https://github.com/Parallels/vagrant-parallels/pull/254)]

IMPROVEMENTS:
  - action/destroy: Destroy suspended VMs without resuming

## 1.6.1 (January 13, 2016)

BUG FIXES:
  - action/import: Fix `regenerate_src_uuid` option behavior in parallel run
    [[GH-241](https://github.com/Parallels/vagrant-parallels/pull/241)]
  - action/box_unregister: Use temporary lock file to prevent early unregister
    in parallel run [[GH-244](https://github.com/Parallels/vagrant-parallels/pull/244)]
  - action/network: Fix detection of the next virtual network ID [[GH-245](https://github.com/Parallels/vagrant-parallels/pull/245)]


## 1.6.0 (December 24, 2015)
BREAKING CHANGES:

  - The required Vagrant version is **1.8** or higher. It is caused by changes
    in Vagrant plugin model.

SUPPORT FOR VAGRANT FEATURES:

  - `vagrant port`: This command displays the list of forwarded ports from the
    guest to the host
  - `vagrant snapshot`: This command can be used to checkpoint and restore
  point-in-time snapshots [[GH-228](https://github.com/Parallels/vagrant-parallels/pull/228)]

IMPROVEMENTS:

  - action/network: Handle a list of bridged NICs [[GH-233](https://github.com/Parallels/vagrant-parallels/pull/233)]
  - action/package: Package machines as plain VMs, not templates [[GH-227](https://github.com/Parallels/vagrant-parallels/pull/227)]
  - action/resume: Provisioners are run on VM resume
  - config: Rename option `use_linked_clone` to `linked_clone`
  - driver: Cache Parallels Desktop version lookup [[GH-234](https://github.com/Parallels/vagrant-parallels/pull/234)]
  - guest_cap/darwin: Parallels Tools auto-update is available for OS X (Darwin)
    guests [[GH-235](https://github.com/Parallels/vagrant-parallels/pull/235)]

BUG FIXES:

  - action/forward_ports: Add parallel-safe lock to avoid collisions of
    forwarded ports in multi-machine env [[GH-226](https://github.com/Parallels/vagrant-parallels/pull/226)]

## Previous Versions

Please, refer to [Releases](https://github.com/Parallels/vagrant-parallels/releases)
page on GitHub.
