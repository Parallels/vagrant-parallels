---
page_title: "Vagrant Share"
sidebar_current: "share"
---

# Vagrant Share

**General Vagrant doc page:** [Vagrant Share](http://docs.vagrantup.com/v2/share/index.html).

Vagrant Share allows you to share your Vagrant environment with anyone in the
world, enabling collaboration directly in your Vagrant environment in almost any
network environment with just a single command: `vagrant share`.

The Parallels provider supports two primary modes or features of Vagrant Share:

* [**HTTP sharing**](http://docs.vagrantup.com/v2/share/http.html) will create a
URL that you can give to anyone. This URL will route directly into your Vagrant
environment. The person using this URL does not need Vagrant installed, so it
can be shared with anyone. This is useful for testing webhooks or showing your
work to clients, teammates, managers, etc.

* [**SSH sharing**](http://docs.vagrantup.com/v2/share/ssh.html) will allow
instant SSH access to your Vagrant environment by anyone by running `vagrant
connect --ssh` on the remote side. This is useful for pair programming,
debugging ops problems, etc.

Vagrant Share requires an account with [Vagrant Cloud](https://vagrantcloud.com/)
to be used.