# Vagrant Parallels Provider
[![Gem Version](https://badge.fury.io/rb/vagrant-parallels.svg)](https://badge.fury.io/rb/vagrant-parallels)
[![Build Status](https://travis-ci.org/Parallels/vagrant-parallels.svg?branch=master)](https://travis-ci.org/Parallels/vagrant-parallels)
[![Code Climate](https://codeclimate.com/github/Parallels/vagrant-parallels.svg)](https://codeclimate.com/github/Parallels/vagrant-parallels)

_Vagrant Parallels Provider_ is a plugin for [Vagrant](https://www.vagrantup.com),
allowing to manage [Parallels Desktop](https://www.parallels.com/products/desktop/)
virtual machines on macOS hosts.

### Requirements
- [Vagrant v1.9.7](https://www.vagrantup.com) or higher
- [Parallels Desktop 11 for Mac](https://www.parallels.com/products/desktop/) or higher

*Note:* Only **Pro** and **Business** editions of **Parallels Desktop for Mac**
are compatible with this Vagrant provider.
Standard edition doesn't have a full command line functionality and can not be used
with Vagrant.

## Features
The Parallels provider supports all basic Vagrant features, including Shared Folders,
Private and Public Networking, Forwarded ports and Vagrant Share.

If you're just getting started with Vagrant, it is highly recommended that you
read the official [Vagrant documentation](https://docs.vagrantup.com/v2/) first.

## Installation
Make sure that you have [Parallels Desktop for Mac](https://www.parallels.com/products/desktop/)
and [Vagrant](https://www.vagrantup.com/downloads.html) properly installed.
We recommend that you use the latest versions of these products.

Parallels provider is a plugin for Vagrant. Run this command to install it:

```
$ vagrant plugin install vagrant-parallels
```

## Provider Documentation

More information about the Parallels provider is available in
[Vagrant Parallels Documentation](https://parallels.github.io/vagrant-parallels/docs/)

We recommend you to start from these pages:
* [Usage](https://parallels.github.io/vagrant-parallels/docs/usage.html)
* [Getting Started](https://parallels.github.io/vagrant-parallels/docs/getting-started.html)
* [Boxes](https://parallels.github.io/vagrant-parallels/docs/boxes/index.html)

## Getting Help

If you have an issue with the Parallels provider or discover a bug,
please report it on the [Issue Tracker](https://github.com/Parallels/vagrant-parallels/issues).

## License and Authors

* Author: Youssef Shahin <yshahin@gmail.com>
* Author: Mikhail Zholobov <legal90@gmail.com>
* Copyright 2013-2023, Parallels International GmbH.

Vagrant Parallels Provider is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
