---
page_title: "Installing Provider"
sidebar_current: "installation"
---

# Installing Provider
First, make sure that you have [Parallels Desktop for Mac](https://www.parallels.com/products/desktop/)
and [Vagrant](https://www.vagrantup.com/downloads.html) properly installed.
We recommend you using the latest versions of these products.

Since the Parallels provider is a Vagrant plugin, installing it is easy:

```
$ vagrant plugin install vagrant-parallels
```

The Vagrant plugin installer will automatically download and install
`vagrant-parallels` plugin.

## Requirements
- Vagrant v1.8 or higher
- Parallels Desktop for Mac version 11 or higher

<div class="alert alert-warn">
    <p>
		Only <strong>Pro</strong> and <strong>Business</strong> editions of
		<strong>Parallels Desktop for Mac</strong> can be used with this Vagrant provider.
	</p>
</div>
