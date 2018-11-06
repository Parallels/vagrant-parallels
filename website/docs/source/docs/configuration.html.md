---
page_title: "Configuration"
sidebar_current: "configuration"
---

# Configuration

While the Parallels provider is a drop-in replacement for VirtualBox, there are
additional features that allow you to more finely configure Parallels-specific
aspects of your machines.

## Virtual Machine Name

You can customize the virtual machine name that appears in the Parallels Desktop
GUI. By default, Vagrant sets it to the name of the folder containing the
Vagrantfile plus a timestamp of when the machine was created.

To change the name, set the `name` property to the desired value:

```ruby
config.vm.provider "parallels" do |prl|
  prl.name = "my_vm"
end
```

## Virtual Machine type: Full Clone vs Linked Clone

Starting since vagrant-parallels v2.0.0, when you create a new virtual machine with
`vagrant up` it is created as a linked clone of the box image.
Previously the provider created a full clone of the box image.

Differences between linked and full clones:

- Linked clone creation is extremely faster than the full cloning, because
there is no image copying process.
- Linked clone requires much less disk space, because initially its hard disk
image is less than 1Mb (it is bound to the parent's snapshot).
- Full clone is a full image copy, which is totally independent from the box.
Linked clones are always bound to the specific snapshot of the box image. That means
that the box deletion will cause all its linked clones being corrupted. Vagrant will
warn you about such cases but you still need be careful when you delete boxes!

If you want the provider to create a full clone instead, you should disable the linked
clone feature explicitly in Vagrantfile:

```ruby
config.vm.provider "parallels" do |prl|
  prl.linked_clone = false
end
```

_Note:_ Changes of this setting will take an effect only for newly created machines.

## Parallels Tools Auto-Update

Parallels Tools is a set of Parallels utilities that ensures a high level of
integration between the host and the guest operating systems (read more:
[Parallels Tools Overview](http://download.parallels.com/desktop/v13/docs/en_US/Parallels%20Desktop%20User's%20Guide/32789.htm)).

By default the Parallels provider checks the status of Parallels Tools after
booting the machine. If they are outdated or newer, a warning message will be
displayed.

You can configure the Parallels provider to update Parallels Tools
automatically:

```ruby
config.vm.provider "parallels" do |prl|
  prl.update_guest_tools = true
end
```

This option is disabled by default because of Parallels Tools installation
takes a significant time (2-6 minutes). Anyway, it runs only when there is a
version mismatch.

Also, you can completely disable the Parallels Tools version check, if you want:

```ruby
config.vm.provider "parallels" do |prl|
  prl.check_guest_tools = false
end
```

In this case the both of Parallels Tools status check and an automatic update
procedure will be skipped as well.

<div id="prlctl"></div>

## Customization with prlctl

Parallels Desktop includes the `prlctl` command-line utility that can be used to
modify the virtual machines settings.


The Parallels provider allows to execute the prlctl command with any of the
available options just prior to booting the virtual machine:

```ruby
config.vm.provider "parallels" do |prl|
  prl.customize ["set", :id, "--device-set", "cdrom0", "--image",
               "/path/to/disk.iso", "--connect"]
end
```

In the example above, the virtual machine is modified to have a specified ISO
image mounted on its virtual media device (cdrom). The `:id` parameter is
replaced with the actual virtual machine ID.

Multiple `customize` directives can be used simultaneously. They will be
executed in the given order.

A simple way is provided to change the memory and CPU settings:

```ruby
config.vm.provider "parallels" do |prl|
  prl.memory = 1024
  prl.cpus = 2
end
```


You can read the [Command-Line Reference](http://download.parallels.com/desktop/v13/docs/en_US/Parallels%20Desktop%20Pro%20Edition%20Command-Line%20Reference.pdf)
for the complete information about the prlctl command and its options.
