---
page_title: "Networking"
sidebar_current: "networking"
---

# Networking

The Parallels provider supports all networking features described in the Vagrant
[Networking](https://www.vagrantup.com/docs/networking/basic_usage.html) documentation.

## Basic Usage

By default, the Parallels provider automatically configures your virtual machine
network adapter to the *Shared* networking type. In order to access the Vagrant
environment created, the Parallels provider uses an IP address, which the
virtual machine leased from the internal DHCP-server.

You don't need to add any heuristic configuration in the Vagrantfile to use
basic communications with your virtual environment.

If desired, the Parallels provider allows to add some other high-level
networking options, such as connecting to a [public network](/docs/networking/public_network.html),
or creating a [private network](/docs/networking/private_network.html).

It is also possible to configure [port forwarding](/docs/networking/forwarded_ports.html)
between the guest virtual machine and your Mac host.
