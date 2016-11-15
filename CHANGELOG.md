## 1.7.0 (November 15, 2016)
BREAKING CHANGES:
  - **Dropped support of Parallels Desktop 8 and 9**. These versions have 
  reached their [End-of-Life and End-of-Support](http://kb.parallels.com/eu/122533).
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