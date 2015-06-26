---
page_title: "Installing Vagrant"
sidebar_current: "installation"
---

# Installing Provider
First, make sure that you have [Parallels Desktop for Mac](http://www.parallels.com/products/desktop/)
and [Vagrant](http://www.vagrantup.com/downloads) properly installed.
We recommend that you to use the latest versions of these products.

Since the Parallels provider is a Vagrant plugin, installing it is easy:

```
$ vagrant plugin install vagrant-parallels
```

The Vagrant plugin installer will automatically download and install
`vagrant-parallels` plugin.

## Requirements
- Parallels Desktop for Mac version 8 or higher
- Vagrant v1.5 or higher
