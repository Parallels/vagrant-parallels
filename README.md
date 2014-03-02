# Vagrant Parallels Provider
[![Gem Version](https://badge.fury.io/rb/vagrant-parallels.png)](http://badge.fury.io/rb/vagrant-parallels)
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

Download the box file, then use vagrant to add the downloaded box using this command. Remember to use `bundle exec` before `vagrant` command if you are in development mode

```
$ vagrant box add --provider=parallels precise64 http://download.parallels.com/desktop/vagrant/precise64.box
```

The box format is basically just the required `metadata.json` file
along with a `Vagrantfile` that does default settings for the
provider-specific configuration for this provider.

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

* Youssef Shahin `@yshahin` - plugin's author
* Mikhail Zholobov `@legal90`
* Kevin Kaland `@wizonesolutions`
* Konstantin Nazarov `@racktear`
* Dmytro Vasylenko `@odi-um`
* Thomas Koschate `@koschate`

and to all the people who are using and testing this provider

