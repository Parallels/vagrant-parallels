---
page_title: "Boxes"
sidebar_current: "boxes"
---

# Boxes

As with [every provider](http://docs.vagrantup.com/v2/providers/basic_usage.html), 
the Parallels provider has a custom box format.

The easiest way to use a box is to add a box from the [Atlas website](https://atlas.hashicorp.com/parallels). 
You can also add and share your own customized boxes there. Read more on the 
[Atlas Help](https://atlas.hashicorp.com/help) page. 

## Discovering boxes

The easiest way to find boxes is to look on the public Vagrant box catalog for a
box matching your use case: [all boxes with the Parallels provider support](https://atlas.hashicorp.com/boxes/search?provider=parallels)

Official boxes compatible with Parallels provider are available on the
[parallels account page](https://atlas.hashicorp.com/parallels)

Adding a box from the catalog is very easy:

```
$ vagrant box add parallels/ubuntu-14.04
...
```

You can also quickly initialize a Vagrant environment with command

```
$ vagrant init parallels/ubuntu-14.04
...
```
