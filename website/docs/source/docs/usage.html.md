---
page_title: "Usage"
sidebar_current: "usage"
---

# Usage

The Parallels provider is used just like any other provider. Please read the
general [basic usage](https://www.vagrantup.com/docs/providers/basic_usage.html)
page for providers.

When Parallels provider is installed it has a higher priority than any other
provider shipped with Vagrant. In most cases you will not have to specify the
provider name, just "vagrant up" will be enough:

- For Macs with Intel chip:

```
$ vagrant init bento/ubuntu-18.04
$ vagrant up
```

- For Macs with Apple M-series chip:

```
$ vagrant init bento/ubuntu-20.04-arm64
$ vagrant up
```

But if you have a multi-provider configuration and/or want to be sure that
exactly `parallels` provider will be used, then you can specify it explicitly:

```
$ vagrant up --provider=parallels
```
