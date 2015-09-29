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

## Create VM as a Linked Clone
<div class="alert alert-info">
	<p>
        <strong>Note:</strong> This feature is available only with Parallels
        Desktop 11 or higher.
	</p>
</div>

When you run `vagrant up` for the first time, the new virtual machine
will be created by cloning the box image. By default the Parallels provider 
creates a regular clone, e.q. the full copy of the box image.

You can configure it to create a linked clone instead:

```ruby
config.vm.provider "parallels" do |prl|
  prl.use_linked_clone = true
end
```

Difference between linked and regular clones:

- Linked clone creation is extremely faster than the regular cloning, because 
there is no image copying process.
- Linked clone require much less disk space, because its hard disk image is less 
than 1Mb initially (it is bound to the parent's snapshot).
- Regular clone is a full image copy, which is independent from the box. 
The linked clone is bound to the specific snapshot of the box image. It means 
that box deletion will cause all its linked clones being corrupted. Then please,
delete your boxes carefully!

## Parallels Tools Auto-Update
<div class="alert alert-info">
	<p>
        <strong>Note:</strong> This feature makes sense to Linux guests only.
        In Windows and Mac OS guests Parallels Tools will be always updated
        automatically by the special installation agent running in GUI mode.
	</p>
</div>

Parallels Tools is a set of Parallels utilities that ensures a high level of
integration between the host and the guest operating systems (read more:
[Parallels Tools Overview](http://download.parallels.com/desktop/v9/ga/docs/en_US/Parallels%20Desktop%20User's%20Guide/32789.htm)).

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


You can read the [Reference Guide](http://download.parallels.com/desktop/v9/ga/docs/en_US/Parallels%20Command%20Line%20Reference%20Guide.pdf)
for the complete information about the prlctl command and its options.