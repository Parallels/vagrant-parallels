# Vagrant Parallels Provider
[![Build Status](https://travis-ci.org/Parallels/vagrant-parallels.png?branch=master)](https://travis-ci.org/Parallels/vagrant-parallels)
[![Code Climate](https://codeclimate.com/github/Parallels/vagrant-parallels.png)](https://codeclimate.com/github/Parallels/vagrant-parallels)

This is a [Vagrant](http://www.vagrantup.com) 1.3+ plugin that adds a [Parallels Desktop](http://www.parallels.com/products/desktop/)
provider to Vagrant, allowing Vagrant to control and provision machines using Parallels Desktop instead of the default Virtualbox.

## Note

This project is still in active development and not all vagrant features have been developed, so please report any issues you might find.
Almost all features are available except for exporting/packaging VM's.  This will be available soon.

We look forward to hearing from you with any issues or features.  Thank you!

## Installation
The latest version of this provider is supporting **only Vagrant 1.4 or higher**.
If you are still using Vagrant 1.3.*, please, specify the plugin version '0.0.9':

- For Vagrant 1.4 or higher execute `vagrant plugin install vagrant-parallels`.
- For Vagrant 1.3.x execute `vagrant plugin install vagrant-parallels --plugin-version 0.0.9`.

## Usage
After installing, then do a `vagrant up` and specify the `parallels` provider. An example is shown below.

```
$ vagrant init
$ vagrant up --provider=parallels
...
```

You need to have a parallels compatible box specified in your `Vagrantfile` before doing a `vagrant up`, please refer to the coming section for instructions.

### Default Provider

When using parallels as your vagrant provider after almost every command you will need to append `--provider=parallels`. To simplify this you can set your default vagrant provider as **parallels**

If you're using BASH

```
# Append to bash
echo "export VAGRANT_DEFAULT_PROVIDER=parallels" | tee -a ~/.bashrc
source ~/.bashrc
```

If you're using ZSH

```
# Append to zsh
echo "export VAGRANT_DEFAULT_PROVIDER=parallels" | tee -a ~/.zshrc
source ~/.zshrc
```

## Box Format

Every provider in Vagrant must introduce a custom box format. This
provider introduces `parallels` boxes. You can download one using this [link](http://download.parallels.com/desktop/vagrant/precise64.box).
That directory also contains instructions on how to build a box.

Download the box file, then use vagrant to add the downloaded box using this command. Remember to use `bundle exec` before `vagrant` command if you are in development mode

```
$ vagrant box add --provider=parallels precise64 http://download.parallels.com/desktop/vagrant/precise64.box
```
***updated box file to fix mac address regeneration issue #42, precise64 is Ubuntu 12.04.4 LTS (GNU/Linux 3.11.0-15-generic x86_64)***

The box format is basically just the required `metadata.json` file
along with a `Vagrantfile` that does default settings for the
provider-specific configuration for this provider.

## Networking
By default 'vagrant-parallels' uses the basic Vagrant networking approach. By default VM has one adapter assigned to the 'Shared' network in Parallels Desktop.
But you can also add one ore more `:private_network` adapters, as described below:

### Private Network
It is fully compatible with basic Vagrant [Private Networks](http://docs.vagrantup.com/v2/networking/private_network.html).
#### Available arguments:
- `type` - IP configuration way: `:static` or `:dhcp` (exactly Symbol object). Default is `:static`. If `:dchp` is set, such interface will get an IP dynamically from default subnet "10.37.129.1/255.255.255.0".
- `mac` - MAC address which will be assigned to this network adapter. If omitted, MAC will be automatically generated at the first `up` of VM.
- `ip` - IP address which will be assigned to this network adapter. It is required only if type is `:static`.
- `netmask` - network mask. Default is `"255.255.255.0"`. It is required only if type is `:static`.
- `nic_type` - Unnecessary argument, means the type of network adapter. Can be any of `"virtio"`, `"e1000"` or `"rtl"`. Default is `"e1000"`.

#### Example:
```ruby
Vagrant.configure("2") do |config|
  config.vm.network :private_network, ip: "33.33.33.50", netmask: "255.255.0.0"
  config.vm.network :private_network, type: :dhcp, nic_type: "rtl"
end
```
It means that two private network adapters will be configured:
1) The first will have static ip '33.33.33.50' and mask '255.255.0.0'. It will be represented as device `"e1000"` by default (e.g. 'Intel(R) PRO/1000 MT').
2) The second adapter will be configured as `"rtl"` ('Realtek RTL8029AS') and get an IP from internal DHCP server, which is working on the default network "10.37.129.1/255.255.255.0".

### Public Network
It is fully compatible with basic Vagrant [Public Networks](http://docs.vagrantup.com/v2/networking/public_network.html).
#### Available arguments (unnecessary, but provider specific):
- `bridge` - target host's interface for bridged network. You can specify full (ex: `Wi-Fi`) or short (ex: `en0`) name of interface. If omitted, you will be asked to choose the interface during the VM boot (or if only one interface exists, it will be chosen automatically).
_Hint:_ Full names of network interfaces are displayed in _System Preferences -> Network_ window, and short names - in the `ifconfig` command output on your Mac.
- `mac` - MAC address which will be assigned to this network adapter. If omitted, MAC will be automatically generated at the first `up` of VM.
- `ip` - IP address which will be assigned to this network adapter. Use it, if you want to configure adapter manually.
- `netmask` - network mask. Default is `"255.255.255.0"`. It is used only in pair with `ip`
- `type` - IP configuration way, only `:dhcp` is available. Use it only if your public network has a valid DHCP server. Otherwise, omit this attribute or use an `ip` and `netmask` described above.
- `nic_type` - type of network adapter. Can be any of `"virtio"`, `"e1000"` or `"rtl"`. Default is `"e1000"`.

#### Example:
```ruby
Vagrant.configure("2") do |config|
  config.vm.network :public_network, bridge: "Wi-Fi", mac: "001C425FC3AB", type: :dhcp
  config.vm.network :public_network, bridge: "en4", ip: "10.3.1.18", netmask: "255.255.252.0"
end
```
It means that two public network adapters will be configured:
1) The first will be bridged to the 'Wi-Fi' host machine's interface and will have the specified MAC address. After the VM boot it will be automatically configured to get an IP from the DHCP server, which is accessible in the 'Wi-Fi' network).
2) The second adapter will be bridged to the interface 'en4' and will have static ip '10.3.1.18' and mask '255.255.252.0'.

## Provider Specific Configuration

Provider allows to define directives for `prlctl set` through `Vagrantfile` in same way as this done in VirtualBox provider.

#### Example:
```ruby
    config.vm.provider :parallels do |parallels|
    parallels.name = "HipHop VM"
    parallels.customize ["set", :id, "--memsize", "1024"]
```

## Development

To work on the `vagrant-parallels` plugin, clone this repository out

```
$ git clone https://github.com/Parallels/vagrant-parallels
$ cd vagrant-parallels
```

Use [Bundler](http://gembundler.com) to get the dependencies:

```
$ bundle
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
and add the following line to your `Vagrantfile`

```ruby
Vagrant.require_plugin "vagrant-parallels"
```

You need to have a compatible box file installed, refer to box file section

Use bundler to execute Vagrant:

```
$ bundle exec vagrant up --provider=parallels
```

After testing you can also build a gem-package by yourself and then install it as a plugin:
(if you have 'vagrant-parallels' plugin already installed, delete it first)

```
$ git clone https://github.com/Parallels/vagrant-parallels
$ cd vagrant-parallels
$ rake build
...
$ vagrant plugin install ./pkg/vagrant-parallels-<version>.gem
...
```
So, now that you have your own plugin installed, check it with the command `vagrant plugin list`

## Contributors

A great thanks to the people who helping this project stand on its feet, thank you

* Kevin Kaland `@wizonesolutions`
* Mikhail Zholobov `@legal90`
* Dmytro Vasylenko `@odi-um`
* Thomas Koschate `@koschate`

and to all the people who are using and testing this tool

## Copyright & license

The MIT License (MIT)

Copyright (c) 2013 Youssef Shahin

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

