# Vagrant Parallels Provider

This is a [Vagrant](http://www.vagrantup.com) 1.2+ plugin that adds an [Parallels](http://www.parallels.com/products/desktop/)
provider to Vagrant, allowing Vagrant to control and provision machines using Parallels insead of the default Virtualbox.

## Note

This project is still in active development and not all vagrant features have been developed, please report any issues you might find.
Almost all features are available except for exporting/packaging VM's this will be available soon isA (ان شاء الله)

We look forward to hearing from you with any issues or features, Thank you

## Usage

Install using standard Vagrant 1.1+ plugin installation methods. After
installing, then do a `vagrant up` and specify the `parallels` provider. An example is shown below.

```
$ vagrant plugin install vagrant-parallels --plugin-prerelease
...
$ vagrant init
$ vagrant up --provider=parallels
...
```

You need to have a paralles compatible box file installed before doing a `vagrnat up`, please refer to the coming section for instaructions.

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

You need to have a compatable box file installed, refer to box file section

Use bundler to execute Vagrant:

```
$ bundle exec vagrant up --provider=parallels
```
