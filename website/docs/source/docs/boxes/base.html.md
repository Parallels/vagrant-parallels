---
page_title: "Creating a Base Box Manually"
sidebar_current: "boxes-base"
---

# Creating a Base Box Manually

<div class="alert alert-warn">
	<p>
		<strong>Warning: Advanced Topic!</strong> Creating a base box can be a
		time consuming and tedious process, and is not recommended for new
		Vagrant users. If you're just getting started with Vagrant, we
		recommend trying to find <a href="https://app.vagrantup.com/boxes/search?provider=parallels">
		existing base boxes</a> to use first.
	</p>
</div>

We strongly recommend [using Packer](/docs/boxes/packer.html) to create reproducible
builds for your base boxes, as well as automating the builds.

This page documents the box format in case if you want to create your own base boxes
manually, from the existing virtual machine.

Prior to reading this page, please check out the [basics of the Vagrant
box file format](https://www.vagrantup.com/docs/boxes/format.html).

## Contents
A Parallels base box is a compressed archive of the necessary contents of
a Parallels "pvm" file. Here is an example of what is contained in such a box:

```
$ tree
.
├── Vagrantfile
├── box.pvm
│   ├── NVRAM.dat
│   ├── VmInfo.pvi
│   ├── config.pvs
│   └── harddisk.hdd
│       └── ...
└── metadata.json
```

`config.pvs` and `<diskname>.hdd` are strictly required for a Parallels virtual
machine.

There is also the "metadata.json" file used by Vagrant itself. This file
contains nothing but the defaults which are documented on the [box format]
(https://www.vagrantup.com/docs/boxes/format.html) page.

## Installed Software

Base boxes for the Parallels provider should have the following software
installed, as a bare minimum:

- SSH server with key-based authentication setup. If you want the box to work
with default Vagrant settings, the SSH user must be set to accept the [insecure
keypair](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant.pub)
that ships with Vagrant.

- [Parallels Tools](https://download.parallels.com/desktop/v16/docs/en_US/Parallels%20Desktop%20User's%20Guide/32791.htm) so that things such as shared
folders can function. There are many other benefits to installing the tools,
such as networking configuration and device mapping.

## Box Size Optimization

Prior to packaging up a box, you should shrink the hard drives as much as
possible. This can be done with `prl_disk_tool`:

```
$ prl_disk_tool compact --hdd /path/to/harddisk.hdd
```

## Packaging

Remove any extraneous files from the "pvm" folder and package it. Be sure to
compress the tar with gzip (done below in a single command) since Parallels
hard disks are not compressed by default.

```
$ cd /path/to/my/box.pvm/..
$ tar cvzf custom.box ./box.pvm ./Vagrantfile ./metadata.json
```
