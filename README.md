# Vagrant Parallels Provider

This is a [Vagrant](http://www.vagrantup.com) 1.2+ plugin that adds an [Parallels](http://www.parallels.com/products/desktop/)
provider to Vagrant, allowing Vagrant to control and provision machines using Parallels insead of the default Virtualbox.

**NOTE:** This plugin requires Vagrant 1.2+,

## Usage

Install using standard Vagrant 1.1+ plugin installation methods. After
installing, `vagrant up` and specify the `parallels` provider. An example is
shown below.

```
$ vagrant plugin install vagrant-parallels
...
$ vagrant up --provider=parallels
...
```

Of course prior to doing this, you'll need to obtain an Parallels-compatible
box file for Vagrant.

## Box Format

Every provider in Vagrant must introduce a custom box format. This
provider introduces `parallels` boxes. You can download one using this [link](https://s3-eu-west-1.amazonaws.com/vagrant-parallels/devbox.box).
That directory also contains instructions on how to build a box.

The box format is basically just the required `metadata.json` file
along with a `Vagrantfile` that does default settings for the
provider-specific configuration for this provider.

## Development

To work on the `vagrant-parallels` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

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
Use bundler to execute Vagrant:
```
$ bundle exec vagrant up --provider=parallels
```
