# Vagrant Parallels Provider
[![Gem Version](https://badge.fury.io/rb/vagrant-parallels.png)](http://badge.fury.io/rb/vagrant-parallels)
[![Build Status](https://travis-ci.org/Parallels/vagrant-parallels.png?branch=master)](https://travis-ci.org/Parallels/vagrant-parallels)
[![Code Climate](https://codeclimate.com/github/Parallels/vagrant-parallels.png)](https://codeclimate.com/github/Parallels/vagrant-parallels)

This is a plugin for [Vagrant](http://www.vagrantup.com),
allowing to power [Parallels Desktop for Mac](http://www.parallels.com/products/desktop/)
based virtual machines.

### Requirements 
- [Vagrant v1.5](http://www.vagrantup.com) or higher
- [Parallels Desktop 8 for Mac](http://www.parallels.com/products/desktop/) or higher

*Note:* In [**Parallels Desktop 11 for Mac**](http://www.parallels.com/products/desktop/), 
only **Pro** and **Business** editions are compatible with this Vagrant provider. 
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
please report it on the [IssueTracker](https://github.com/Parallels/vagrant-parallels).

## License and Authors

* Author: Youssef Shahin <yshahin@gmail.com>
* Author: Mikhail Zholobov <legal90@gmail.com>
* Copyright 2013-2015, Parallels IP Holdings GmbH.

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
```
