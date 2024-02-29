---
page_title: "Build Base Boxes with Packer"
sidebar_current: "boxes-packer"
---

# Build Base Boxes with Packer

<div class="alert alert-warn">
  <p>
    <strong>Warning: Advanced Topic!</strong> If you're not familiar with
    Packer, you should read the <a href="https://www.packer.io/docs">
    Packer documentation</a> first.
  </p>
</div>

Packer must be properly installed in order to build a new base box using templates.
Read the installation instruction here: [Install Packer](https://www.packer.io/docs/installation.html)

## Packer Templates
Packer is shipped with `parallels-iso` builder, which can be used to create
base Vagrant boxes for the Parallels provider.

There are two popular projects containing Packer templates for `parallels-iso` builder:

- [Bento](https://github.com/chef/bento)
- [Boxcutter](https://github.com/boxcutter/)

## Building a Box

This is an example how to build Vagrant box for Parallels provider:

```
$ packer build -only=parallels-iso template.json
```

Packer will done everything you need: it will download an ISO image, setup a VM,
install Parallels Tools, make basic provisioning, and it will export the VM image
to a `*.box` file

You can read more about options which all supported template options here:
["parallels-iso" builder documentation](https://www.packer.io/docs/builders/parallels-iso.html)
