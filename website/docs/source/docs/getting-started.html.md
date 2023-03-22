---
page_title: "Getting Started"
sidebar_current: "gettingstarted"
---

# Getting Started

This page describes steps to get your first Parallels Desktop virtual machine
managed by Vagrant.

First, download and install [Vagrant for Mac](https://www.vagrantup.com/downloads.html).
Second, install the 'vagrant-parallels' plugin:

```
$ vagrant plugin install vagrant-parallels
```

Once the installation is complete, you can create a virtual machine and manage
it using Vagrant. The following describes how to create a virtual machine.

## New project setup

Create a new directory and init the new Vagrant project in it:

- For Macs with Intel chip:

```
$ vagrant init bento/ubuntu-18.04
$ vagrant up --provider=parallels
```

- For Macs with Apple M-series chip:

```
$ vagrant init bento/ubuntu-20.04-arm64
$ vagrant up --provider=parallels
```

Vagrant will automatically download and import the box and create a new virtual
machine form it. The virtual machine will then be configured and started.

When the virtual machine is up and running, you can log in to it via SSH:

```
$ vagrant ssh
```

You can use other [vagrant commands](https://www.vagrantup.com/docs/cli/index.html)
to control your virtual machine.

For example, you can run `vagrant halt` to gracefully shut it down, or
`vagrant destroy` to remove it completely.
