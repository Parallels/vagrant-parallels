# Vagrant Parallels Provider
[![Gem Version](https://badge.fury.io/rb/vagrant-parallels.png)](http://badge.fury.io/rb/vagrant-parallels)
[![Build Status](https://travis-ci.org/Parallels/vagrant-parallels.png?branch=master)](https://travis-ci.org/Parallels/vagrant-parallels)
[![Code Climate](https://codeclimate.com/github/Parallels/vagrant-parallels.png)](https://codeclimate.com/github/Parallels/vagrant-parallels)

This is a plugin for [Vagrant](http://www.vagrantup.com),
allowing to manage [Parallels Desktop](http://www.parallels.com/products/desktop/) 
virtual machines on OS X hosts.

### Requirements 
- [Vagrant v1.8](http://www.vagrantup.com) or higher
- [Parallels Desktop 10 for Mac](http://www.parallels.com/products/desktop/) or higher

*Note:* Only **Pro** and **Business** editions of **Parallels Desktop for Mac** 
are compatible with this Vagrant provider. 
Standard edition doesn't have a command line functionality and can not be used 
with Vagrant.

## Features
The Parallels provider supports all basic Vagrant features, including shared folders,
private and public networks, forwarded ports and so on. 

If you're just getting started with Vagrant, it is highly recommended that you
read the official [Vagrant documentation](http://docs.vagrantup.com/v2/) first.

## Installation
First, make sure that you have [Parallels Desktop for Mac](http://www.parallels.com/products/desktop/)
and [Vagrant](http://www.vagrantup.com/downloads) properly installed.
We recommend that you use the latest versions of these products.

Since the Parallels provider is a Vagrant plugin, installing it is easy:

```
$ vagrant plugin install vagrant-parallels
```

## Provider Documentation

More information about the Parallels provider is available in
[Vagrant Parallels Documentation](http://parallels.github.io/vagrant-parallels/docs/)

We recommend you to start from these pages:
* [Usage](http://parallels.github.io/vagrant-parallels/docs/usage.html)
* [Getting Started](http://parallels.github.io/vagrant-parallels/docs/getting-started.html)
* [Boxes](http://parallels.github.io/vagrant-parallels/docs/boxes/index.html)

## Getting Help
Having problems while using the provider? Ask your question on the official forum:
["Parallels Provider for Vagrant" forum branch](http://forum.parallels.com/forumdisplay.php?737-Parallels-Provider-for-Vagrant)

If you get an error while using the Parallels provider or discover a bug,
please report it on the [Issue Tracker](https://github.com/Parallels/vagrant-parallels/issues).

## License and Authors

* Author: Youssef Shahin <yshahin@gmail.com>
* Author: Mikhail Zholobov <legal90@gmail.com>
* Copyright 2013-2016, Parallels IP Holdings GmbH.

Vagrant Parallels Provider is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT).