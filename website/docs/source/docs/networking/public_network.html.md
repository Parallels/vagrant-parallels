---
page_title: "Public Networks - Networking"
sidebar_current: "networking-public"
---

# Public Networks

**General Vagrant doc page**: [Public Networks]
(https://www.vagrantup.com/docs/networking/public_network.html).

Public networking by the Parallels provider is fully compatible with the basic
Vagrant approach.

In order to implement a public network, the Parallels provider configures a
[Bridged](https://download.parallels.com/desktop/v16/docs/en_US/Parallels%20Desktop%20User's%20Guide/33015.htm)
network.

## DHCP

The easiest way to use a public network is to allow the IP address to be
assigned via DHCP. Use the following syntax to define a public network:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "public_network"
end
```

When DHCP is used, the IP address can be determined by using `vagrant ssh` to
SSH into the machine and using the appropriate command-line tool to find the
address, such as `ifconfig`.

## Default Network Interface

If more than one network interface is available in the host machine, Vagrant
will ask you to choose which interface the virtual machine should bridge to. A
default interface can be specified by adding a `bridge` clause to the network
definition.

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "public_network", bridge: "en1"
end
```

The string identifying the desired interface must match either the name or
identifier of an available interface. If it can't be found, Vagrant will ask you
to pick the one from a list of available network interfaces.

It is also possible to specify a list of adapters to bridge against:

```ruby
config.vm.network "public_network", bridge: ["en1", "en6"]
```

In this case, Vagrant will use the first network adapter which exists and can be
used as a bridge.
