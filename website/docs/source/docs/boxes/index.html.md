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

For Macs with Apple M-series chip use ARM-based boxes:
[https://app.vagrantup.com/boxes/search?provider=parallels&q=arm](https://app.vagrantup.com/boxes/search?provider=parallels&q=arm)

Adding a box from the catalog is very easy:

```
$ vagrant box add bento/ubuntu-18.04
...
```

You can also quickly initialize a Vagrant environment with the command:

- For Macs with Intel chip:

```
$ vagrant init bento/ubuntu-18.04
...
```

- For Macs with Apple M-series chip:

```
$ vagrant init bento/ubuntu-20.04-arm64
...
```
