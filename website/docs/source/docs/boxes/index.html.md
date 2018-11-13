---
page_title: "Boxes"
sidebar_current: "boxes"
---

# Boxes

As with [every provider](https://www.vagrantup.com/docs/providers/basic_usage.html),
the Parallels provider has a custom box format.

The actual list of official boxes provided by Parallels is available
[on wiki page](https://github.com/Parallels/vagrant-parallels/wiki/Available-Vagrant-Boxes).

All boxes from Parallels could be found on the ["parallels" page on Vagrant Cloud ](https://app.vagrantup.com/parallels).
You can also create and share your own customized boxes there. Read more on the
[Vagrant Cloud](https://www.vagrantup.com/docs/vagrant-cloud/boxes/create.html)
documentation page.

## Discovering Boxes

All boxes for "parallels" provider could be found on Vagrant Cloud:
[https://app.vagrantup.com/boxes/search?provider=parallels](https://app.vagrantup.com/boxes/search?provider=parallels)

Adding a box from the catalog is very easy:

```
$ vagrant box add bento/ubuntu-18.04
...
```

You can also quickly initialize a Vagrant environment with the command:

```
$ vagrant init bento/ubuntu-18.04
...
```
