# Vagrant Parallels Provider

This is a [Vagrant](http://www.vagrantup.com) 1.3+ plugin that adds a [Parallels Desktop](http://www.parallels.com/products/desktop/)
provider to Vagrant, allowing Vagrant to control and provision machines using Parallels Desktop insead of the default Virtualbox.

## Note

This project is still in active development and not all vagrant features have been developed, please report any issues you might find.
Almost all features are available except for exporting/packaging VM's.  This will be available soon.

We look forward to hearing from you with any issues or features.  Thank you!

## Usage
Install using standard Vagrant 1.1+ plugin installation methods. After installing, then do a `vagrant up` and specify the `parallels` provider. An example is shown below.

```
$ vagrant plugin install vagrant-parallels
...
$ vagrant init
$ vagrant up --provider=parallels
...
```

You need to have a parallels compatible box file installed before doing a `vagrant up`, please refer to the coming section for instructions.

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
provider introduces `parallels` boxes. You can download one using this [link](https://s3-eu-west-1.amazonaws.com/vagrant-parallels/devbox.box).
That directory also contains instructions on how to build a box.

Download the box file, then use vagrant to add the downloaded box using this command. Remember to use `bundle exec` before `vagrant` command if you are in development mode

```
$ wget https://s3-eu-west-1.amazonaws.com/vagrant-parallels/devbox.box
$ vagrant box add devbox devbox.box --provider=parallels
```

The box format is basically just the required `metadata.json` file
along with a `Vagrantfile` that does default settings for the
provider-specific configuration for this provider.

## Development

To work on the `vagrant-parallels` plugin, clone this repository out

```
$ git clone https://github.com/yshahin/vagrant-parallels
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
$ git clone https://github.com/yshahin/vagrant-parallels
$ cd vagrant-parallels
$ rake build
...
$ vagrant plugin install ./pkg/vagrant-parallels-<version>.gem
...
```
So, now that you have your own plugin installed, check it with the command `vagrant plugin list`
