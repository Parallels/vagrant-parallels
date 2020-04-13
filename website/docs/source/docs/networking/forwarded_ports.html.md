---
page_title: "Forwarded Ports - Networking"
sidebar_current: "networking-fp"
---

# Forwarded Ports

**General Vagrant doc page**: [Forwarded Ports]
(https://www.vagrantup.com/docs/networking/forwarded_ports.html).

## Defining a Forwarded Port

The forwarded port configuration expects two parameters, the port on the
guest and the port on the host. Example:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "forwarded_port", guest: 80, host: 8080
end
```

This will allow accessing port 80 on the guest via port 8080 on the host.

## Options Reference

This is a complete list of the options that are available for forwarded
ports. Only the `guest` and `host` options are required. Below this section,
there are more detailed examples of using these options.

* `guest` (int) - The port on the guest that you want to be exposed on
  the host. This can be any port.

* `host` (int) - The port on the host that you want to use to access the
  port on the guest. It is recommended to use port greater than 1024.

* `protocol` (string) - Either "udp" or "tcp". This specifies the protocol
  that will be allowed through the forwarded port. By default this is "tcp".

## Port Collisions and Correction

It is common when running multiple Vagrant machines to unknowingly create
forwarded port definitions that collide with each other (two separate
Vagrant projects forwarded to port 8080, for example). Vagrant includes
built-in mechanism to detect this and correct it, automatically.

Port collision detection is always done. Vagrant will not allow you to
define a forwarded port where the port on the host appears to be accepting
traffic or connections.

Port collision auto-correction must be manually enabled for each forwarded
port, since it is often surprising when it occurs and can lead the Vagrant
user to think that the port wasn't properly forwarded. Enabling auto correct
is easy:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "forwarded_port", guest: 80, host: 8080,
    auto_correct: true
end
```

The final `:auto_correct` parameter set to true tells Vagrant to auto
correct any collisions. During a `vagrant up` or `vagrant reload`, Vagrant
will output information about any collisions detections and auto corrections
made, so you can take notice and act accordingly.
