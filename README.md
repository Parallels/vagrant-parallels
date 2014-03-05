# Vagrant Parallels Provider
[![Gem Version](https://badge.fury.io/rb/vagrant-parallels.png)](http://badge.fury.io/rb/vagrant-parallels)
[![Build Status](https://travis-ci.org/Parallels/vagrant-parallels.png?branch=master)](https://travis-ci.org/Parallels/vagrant-parallels)
[![Code Climate](https://codeclimate.com/github/Parallels/vagrant-parallels.png)](https://codeclimate.com/github/Parallels/vagrant-parallels)

This is a plugin for [Vagrant](http://www.vagrantup.com),
allowing to power virtual machines by
[Parallels Desktop for Mac](http://www.parallels.com/downloads/desktop/).

### Requirements
- Parallels Desktop for Mac 8 or 9
- Vagrant v1.4 or higher

If you're just getting started with Vagrant, it is highly recommended that you
read the official [Vagrant documentation](http://docs.vagrantup.com/v2/) first.

## Features
Parallels provider supports all basic Vagrant features, except one: **"Forwarded ports" configuration is not available yet**.

It might be implemented in the future, after the next release of Parallels Desktop for Mac.

## Installation
First of all make sure that you have [Parallels Desktop for Mac](http://www.parallels.com/products/desktop/)
and [Vagrant](http://www.vagrantup.com/downloads) properly installed.
We recommend that you use the latest versions of these products.

Since Parallels provider is a Vagrant plugin, installing is easy:

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

You need to have a parallels compatible box specified in your `Vagrantfile`
before doing a `vagrant up`, please refer to the *Boxes* section for instructions.

### Default Provider

You can use `VAGRANT_DEFAULT_PROVIDER` environmental variable to specify the
default provider. Just set it to `parallels` and then it wont be necessary
to add `--provider` flag to vagrant commands.

```
export VAGRANT_DEFAULT_PROVIDER=parallels
```

You can also add this command to your `~/.bashrc` file
(or `~/.zshrc` if your shell is Zsh) to make this setting permanent.

## Boxes

Every provider in Vagrant must introduce a custom box format.

As with every provider, Parallels provider has a custom box format.
There is a list of popular base boxes for Parallels provider:

- Ubuntu 12.04 x86_64:
[http://download.parallels.com/desktop/vagrant/precise64.box]
(http://download.parallels.com/desktop/vagrant/precise64.box)

- Ubuntu 13.10 x86_64:
[http://download.parallels.com/desktop/vagrant/saucy64.box]
(http://download.parallels.com/desktop/vagrant/saucy64.box)

- CentOS 6.5 x86_64:-
[http://download.parallels.com/desktop/vagrant/centos64.box]
(http://download.parallels.com/desktop/vagrant/centos64.box)

You can add one of these boxes using the next command:

```
$ vagrant box add --provider=parallels precise64 http://download.parallels.com/desktop/vagrant/precise64.box
```

## Networking
By default Vagrant Parallels provider uses the basic Vagrant networking
approach. Initially VM has one adapter assigned to the 'Shared' network
in Parallels Desktop.

But you can also add `:private_network` and `:public_network` adapters.
These features are working by the same way as in the basic Vagrant:
- [Private Networks]
(http://docs.vagrantup.com/v2/networking/private_network.html)
- [Public Networks]
(http://docs.vagrantup.com/v2/networking/public_network.html)

## Provider Specific Configuration

Parallels Desktop has a `prlctl` utility that can be used to make modifications
to Parallels virtual machines from the command line.


Parallels provider exposes a way to call any command against *prlctl* just prior
to booting the machine:

```ruby
config.vm.provider "parallels" do |v|
  v.customize ["set", :id, "--device-set", "cdrom0", "--image",
               "/path/to/disk.iso", "--connect"]
end
```

In the example above, the VM is modified to have a specified iso image attached
to it's virtual media device (cdrom). Some details:

* The `:id` special parameter is replaced with the ID of the virtual
  machine being created, so when a *prlctl* command requires an ID, you
  can pass this special parameter.

* Multiple `customize` directives can be used. They will be executed in the
  order given.

There are some convenience shortcuts for memory and CPU settings:

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

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is added to *.gitignore*)
and add the following line to your `Vagrantfile`

```ruby
Vagrant.require_plugin "vagrant-parallels"
```

You need to have a compatible box file installed, refer to the *Boxes* section

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
So, now that you have your own plugin installed, check it with the command
`vagrant plugin list`

## Contributing

1. Fork it.
2. Create a branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Added a sweet feature"`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a pull request from your `my-new-feature` branch into master

## Getting help
Having problems while using our provider? Ask your question to our mailing list:
[Google Group](https://groups.google.com/group/vagrant-parallels)

If you've got a strange error while using Parallels provider, or found a bug
there  - please, report it on [Issue Tracker](https://github.com/Parallels/vagrant-parallels).

## Credits
Great thanks to *Youssef Shahin* `@yshahin` for having initiated the development
of this provider. You've done a great job, Youssef!

Also, thanks to the people who helping this project stand on its feet, thank you

* Mikhail Zholobov `@legal90`
* Kevin Kaland `@wizonesolutions`
* Konstantin Nazarov `@racktear`
* Dmytro Vasylenko `@odi-um`
* Thomas Koschate `@koschate`

and to all the people who are using and testing this provider.

