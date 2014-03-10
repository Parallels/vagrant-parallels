# Vagrant Parallels Provider
[![Gem Version](https://badge.fury.io/rb/vagrant-parallels.png)](http://badge.fury.io/rb/vagrant-parallels)
[![Build Status](https://travis-ci.org/Parallels/vagrant-parallels.png?branch=master)](https://travis-ci.org/Parallels/vagrant-parallels)
[![Code Climate](https://codeclimate.com/github/Parallels/vagrant-parallels.png)](https://codeclimate.com/github/Parallels/vagrant-parallels)

This is a plugin for [Vagrant](http://www.vagrantup.com),
allowing to power [Parallels Desktop for Mac](http://www.parallels.com/downloads/desktop/)
based virtual machines.

### Requirements
- Parallels Desktop for Mac 8 or 9
- Vagrant v1.4 or higher

If you're just getting started with Vagrant, it is highly recommended that you
read the official [Vagrant documentation](http://docs.vagrantup.com/v2/) first.

## Features
The Parallels provider supports all basic Vagrant features, except one:
**"Forwarded ports" configuration is not available yet**.

It might be implemented in the future, after the next release of Parallels
Desktop for Mac.

## Installation
First, make sure that you have [Parallels Desktop for Mac](http://www.parallels.com/products/desktop/)
and [Vagrant](http://www.vagrantup.com/downloads) properly installed.
We recommend that you use the latest versions of these products.

Since the Parallels provider is a Vagrant plugin, installing it is easy:

```
$ vagrant plugin install vagrant-parallels
```

## Usage
Parallels provider is used just like any other provider. Please read the general
[basic usage](http://docs.vagrantup.com/v2/providers/basic_usage.html) page for
providers.

The value to use for the `--provider` flag is `parallels`:

```
$ vagrant init
$ vagrant up --provider=parallels
...
```

You need a Parallels compatible box specified in your `Vagrantfile`
before doing `vagrant up`, please refer to the *Boxes* section for instructions.

### Default Provider

You can use `VAGRANT_DEFAULT_PROVIDER` environment variable to specify the
default provider. Just set it to `parallels` and then it will not be necessary
to add the `--provider` flag to vagrant commands.

```
export VAGRANT_DEFAULT_PROVIDER=parallels
```

You can also add this command to the `~/.bashrc` file
(or `~/.zshrc` if your shell is Zsh) to make this setting permanent.

## Boxes

Every provider in Vagrant must introduce a custom box format.

As with every provider, the Parallels provider has a custom box format.
The following base boxes for Parallels provider are available:

- Ubuntu 12.04 x86_64:
[http://download.parallels.com/desktop/vagrant/precise64.box]
(http://download.parallels.com/desktop/vagrant/precise64.box)

- Ubuntu 13.10 x86_64:
[http://download.parallels.com/desktop/vagrant/saucy64.box]
(http://download.parallels.com/desktop/vagrant/saucy64.box)

- CentOS 6.5 x86_64:-
[http://download.parallels.com/desktop/vagrant/CentOS-6.5-x86_64.box]
(http://download.parallels.com/desktop/vagrant/CentOS-6.5-x86_64.box)

- CentOS 5.9 x86_64:-
[http://download.parallels.com/desktop/vagrant/CentOS-5.9-x86_64.box]
(http://download.parallels.com/desktop/vagrant/CentOS-5.9-x86_64.box)

You can add one of these boxes using the next command:

```
$ vagrant box add --provider=parallels precise64 http://download.parallels.com/desktop/vagrant/precise64.box
```

## Networking
By default, The Parallels provider uses the basic Vagrant networking
approach. Initially, a virtual machine has one adapter assigned to the 'Shared' network
in Parallels Desktop.

In addition, you can add `:private_network` and `:public_network` adapters.
These features are working the same way as in the basic Vagrant:
- [Private Networks]
(http://docs.vagrantup.com/v2/networking/private_network.html)
- [Public Networks]
(http://docs.vagrantup.com/v2/networking/public_network.html)

## Provider Specific Configuration

Parallels Desktop has the `prlctl` command-line utility that can be used to make modifications
to Parallels virtual machines.


The Parallels provider allows to execute the prlctl command with any of avialable options just prior
to starting a virtual machine:

```ruby
config.vm.provider "parallels" do |v|
  v.customize ["set", :id, "--device-set", "cdrom0", "--image",
               "/path/to/disk.iso", "--connect"]
end
```

In the example above, the virtual machine is modified to have a specified ISO image mounted
on it's virtual media device (cdrom). The `:id` parameter is replaced with the actual virtual machine ID.

Multiple `customize` directives can be used. They will be executed in the
given order.

The virtual machine memory and CPU settings can be modified easily:

```ruby
config.vm.provider "parallels" do |v|
  v.memory = 1024
  v.cpus = 2
end
```

## Development

To work on the `vagrant-parallels` plugin development, clone this repository:

```
$ git clone https://github.com/Parallels/vagrant-parallels
$ cd vagrant-parallels
```

Use [Bundler](http://gembundler.com) to get the dependencies (Ruby 2.0 is needed):

```
$ bundle
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If they pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by simply
creating a `Vagrantfile` in the top level of this directory (it is added to *.gitignore*)
and add the following line to your `Vagrantfile`

```ruby
Vagrant.require_plugin "vagrant-parallels"
```

You need a compatible box file installed. Refer to the *Boxes* section.

Use bundler to execute Vagrant:

```
$ bundle exec vagrant up --provider=parallels
```

###Installing Parallels Provider From Source

If you want to globally install your locally built plugin from source, use the following method:

```
$ cd vagrant-parallels
$ bundle install
...
$ bundle exec rake build
...
$ vagrant plugin install pkg/vagrant-parallels-<version>.gem
...
```
Now that you have your own plugin installed, check it with the command
`vagrant plugin list`

## Contributing

1. Fork it.
2. Create a branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Added a sweet feature"`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a pull request from your `my-new-feature` branch into master

## Getting help
Having problems while using the provider? Ask your question to our mailing list:
[Google Group](https://groups.google.com/group/vagrant-parallels)

If you get an error while using the Parallels provider or discover a bug,
please report it on the [IssueTracker](https://github.com/Parallels/vagrant-parallels).

## Credits
Great thanks to *Youssef Shahin* `@yshahin` for having initiated the development
of this provider. You've done a great job, Youssef!

Also, thanks to the people who are helping this project stand on its feet, thank you

* Mikhail Zholobov `@legal90`
* Kevin Kaland `@wizonesolutions`
* Konstantin Nazarov `@racktear`
* Dmytro Vasylenko `@odi-um`
* Thomas Koschate `@koschate`

and to all the people who are using and testing this provider.

