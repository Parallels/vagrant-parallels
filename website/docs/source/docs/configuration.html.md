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
config.vm.provider "parallels" do |v|
  v.name = "my_vm"
end
```

## Parallels Tools Auto-Update
Parallels Tools is a set of Parallels utilities that ensures a high level of
integration between the host and the guest operating systems (read more:
[Parallels Tools Overview](http://download.parallels.com/desktop/v9/ga/docs/en_US/Parallels%20Desktop%20User's%20Guide/32789.htm)).

By default, the Parallels provider checks the status of Parallels Tools after
booting the machine. If they are outdated or newer, a warning message will be
displayed.


You can configure the Parallels provider to update Parallels Tools
automatically:

```ruby
config.vm.provider "parallels" do |v|
  v.update_guest_tools = true
end
```

This option is disabled by default because of Parallels Tools installation
takes a significant time (2-6 minutes). Anyway, it runs only when there is a
version mismatch.

Also, you can completely disable the Parallels Tools version check, if you want:

```ruby
config.vm.provider "parallels" do |v|
  v.check_guest_tools = false
end
```

In this case the both of Parallels Tools status check and an automatic update
procedure will be skipped as well.

<div class="alert alert-info">
	<p>
        <strong>Note:</strong> The feature of Parallels Tools Auto-Update is
        related to Linux guest OS only.
        In Windows and Mac OS guests Parallels Tools will be always updated
        automatically by the special installation agent running in GUI mode.
	</p>
</div>

## Power Consumption Mode
The Parallels provider sets power consumption method as "Longer Battery 
Life" by default. You can override it to "Better Performance" using this 
customisation parameter:

```ruby
config.vm.provider "parallels" do |v| 
  v.optimize_power_consumption = false
end
```

P.s. Read more about power consumption modes in Parallels Desktop: [KB #9607]
(http://kb.parallels.com/en/9607)

## prlctl Customization

Parallels Desktop includes the `prlctl` command-line utility that can be used to
modify the virtual machines settings.


The Parallels provider allows to execute the prlctl command with any of the
available options just prior to booting the virtual machine:

```ruby
config.vm.provider "parallels" do |v|
  v.customize ["set", :id, "--device-set", "cdrom0", "--image",
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
config.vm.provider "parallels" do |v|
  v.memory = 1024
  v.cpus = 2
end
```


You can read the [Reference Guide](http://download.parallels.com/desktop/v9/ga/docs/en_US/Parallels%20Command%20Line%20Reference%20Guide.pdf)
for the complete information about the prlctl command and its options.