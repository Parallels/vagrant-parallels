---
page_title: "Shared Folders"
sidebar_current: "sharedfolders"
---

# Shared Folders

By default, Vagrant will share your project directory (the directory with the Vagrantfile) to /vagrant.

If you need to add other folders, then you can to specify them in a Vagrantfile this way:

```ruby
config.vm.synced_folder "~/", "/media/psf/Home"
config.vm.synced_folder "/", "/media/psf/Mac_Root"
```

You might want to share folders by passing Parallels Command Line as described in [Customization with prlctl](/docs/configuration.html#prlctl), but it won't work. It is done to avoid conflicts and keep vagrant configs more platform agnostic.

You can read more about syncing host and guest folders in the [Vagrant Documentation](https://www.vagrantup.com/docs/synced-folders/basic_usage.html).
