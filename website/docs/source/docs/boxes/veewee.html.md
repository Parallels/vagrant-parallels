---
page_title: "Build Base Boxes with Veewee"
sidebar_current: "boxes-veewee"
---

# Build Base Boxes with Veewee

<div class="alert alert-warn">
	<p>
		<strong>Warning: Advanced Topic!</strong> If you're not familiar with
		Veewee, you should read the <a href="https://github.com/jedi4ever/veewee/blob/master/README.md">
		Veewee documentation</a> first.
	</p>
</div>

Veewee must be properly installed in order to build a new base box using one of
the existing Veewee templates. If you haven't installed it yet, please refer to
the [Veewee Installation](https://github.com/jedi4ever/veewee/blob/master/doc/installation.md)
instructions.

## Parallels Virtualization SDK

Veewee requires the 'prlsdkapi' Python module from the Parallels Virtualization
SDK to interact with Parallels Desktop and virtual machines. To use Veewee with
the Parallels provider you need to download and install this SDK package:
[The Parallels Virtualization SDK for Mac](https://www.parallels.com/download/pvsdk/)

You can also install it with [Homebrew](brew.sh) package manager:

```
$ brew install parallels-virtualization-sdk
```

## Preparing a definition

List available Veewee templates, choose what you want to use and create a
definition:

```
$ veewee parallels templates
$ veewee parallels define 'my_centos' 'CentOS-6.5-x86_64-minimal'
```

Since most of the default templates are not ready to be used with the Parallels
provider, you need to customize the definition manually.

Navigate to the definition folder and create a `parallels.sh` script with the
following content:

```
$ vi ./definition/my_centos/parallels.sh

# Install the Parallels Tools
PARALLELS_TOOLS_ISO=prl-tools-lin.iso
mkdir -p /media/cdrom
mount -o loop $PARALLELS_TOOLS_ISO /media/cdrom
/media/cdrom/install --install-unattended-with-deps --progress
umount /media/cdrom
```

Open the `definition.rb` file for editing, find the ':postinstall_files' array
and add the "parallels.sh" string to it. It should now look like this:

```
$ vi ./definition/my_centos/definition.rb

...
  :postinstall_files => [
     "base.sh",
     "ruby.sh",
     "chef.sh",
     "puppet.sh",
     "vagrant.sh",
     "parallels.sh",
     "cleanup.sh",
  ],
...
```

Please observe the following important rules:

- You can insert `"parallels.sh"` on any position of this array, but it's
necessary to place it between `"base.sh"` and `"cleanup.sh"`
- You also have to comment (or delete) strings like "vbox.sh" or "virtualbox.sh",
to prevent VirtualBox customization.

## Building a VM Image

After customizing the definition you can start building a vm image:

```
$ veewee parallels build 'my_centos'
```

This action can take a long time to complete because it involves downloading the
ISO image, installing the OS, and configuring it after the installation.

## Exporting

```
$ veewee parallels export 'my_centos'
```

The virtual machine will be shut down, exported, and packed in the `my_centos.box`
file inside the current directory. When it's done, you can use it as any other
box for the Parallels provider.
