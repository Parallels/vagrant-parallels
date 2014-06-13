# Vagrant Parallels Provider
[![Gem Version](https://badge.fury.io/rb/vagrant-parallels.png)](http://badge.fury.io/rb/vagrant-parallels)
[![Build Status](https://travis-ci.org/Parallels/vagrant-parallels.png?branch=master)](https://travis-ci.org/Parallels/vagrant-parallels)
[![Code Climate](https://codeclimate.com/github/Parallels/vagrant-parallels.png)](https://codeclimate.com/github/Parallels/vagrant-parallels)

This is a plugin for [Vagrant](http://www.vagrantup.com),
allowing to power [Parallels Desktop for Mac](http://www.parallels.com/downloads/desktop/)
based virtual machines.

### Requirements
- Parallels Desktop for Mac 8 or 9
- Vagrant v1.5 or higher

If you're just getting started with Vagrant, it is highly recommended that you
read the official [Vagrant documentation](http://docs.vagrantup.com/v2/) first.

## Features
The Parallels provider supports all basic Vagrant features, except the next:
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

## Provider Documentation

More information about the Parallels provider is available in
[Vagrant Parallels Documentation](http://parallels.github.io/vagrant-parallels/docs/)

We recommend you to start from these pages:
* [Usage](http://parallels.github.io/vagrant-parallels/docs/usage.html)
* [Getting Started](http://parallels.github.io/vagrant-parallels/docs/getting-started.html)
* [Boxes](http://parallels.github.io/vagrant-parallels/docs/boxes/index.html)

## Getting Help
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

