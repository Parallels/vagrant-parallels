---
page_title: "Private Networks - Networking"
sidebar_current: "networking-private"
---

# Private Networks

**General Vagrant doc page**: [Private Networks]
(https://www.vagrantup.com/docs/networking/private_network.html).

Private networking by the Parallels provider is fully compatible with the basic
Vagrant approach.

In order to implement a private network, the Parallels provider configures the
internal [Host-Only](https://download.parallels.com/desktop/v16/docs/en_US/Parallels%20Desktop%20User's%20Guide/33018.htm)
network.

## DHCP

The easiest way to use a private network is to allow the IP address to be assigned
via DHCP.

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "private_network", type: "dhcp"
end
```

This will automatically assign an IP address from the reserved address space.
The IP address can be determined by using `vagrant ssh` to SSH into the virtual
machine and using the appropriate command-line tool to find the IP, such as
`ifconfig`.

## Static IP

You can also specify a static IP address for the machine. This lets you access
the Vagrant managed machine using a static (known) IP address. The Vagrantfile
for a static IP address should look like this:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "private_network", ip: "192.168.50.4"
end
```

It is a responsibility of the user to ensure that the static IP address does not
conflict with any other machines on the same network.

While you can choose any IP address, you _should_ use an IP from the
[reserved private address space](https://en.wikipedia.org/wiki/Private_network#Private_IPv4_address_spaces).
These addresses are guaranteed to never be publicly routable, and most routers
actually block traffic from going to them from the outside world.
