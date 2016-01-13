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