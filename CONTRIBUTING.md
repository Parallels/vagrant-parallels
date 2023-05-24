## How to contribute

We are glad you want to contribute to the `vagrant-parallels` plugin!
First of all,  clone this repository:

```
$ git clone https://github.com/Parallels/vagrant-parallels
$ cd vagrant-parallels
```

### Dependencies and Unit Tests

To hack on our plugin, you'll need a [Ruby interpreter](https://www.ruby-lang.org/en/downloads/)
(>= 3.0) and [Bundler](https://bundler.io/) which can be installed with a simple
`gem install bundler`. Afterwards, do the following:

```
$ bundle install
$ bundle exec rake
```

This will run the unit test suite, which should come back all green!
Then you're good to go!

If you want to run Vagrant without having to install the `vagrant-parallels`
gem, you may use `bundle exec`, like so:

```
$ bundle exec vagrant up --provider=parallels
```

### Building Provider from Source
To build a `vagrant-parallels` gem just run this command:

```
$ bundle exec rake build
```

The built "gem" package will appear in the `./pkg` folder.

Then, if you want to install plugin from your locally built "gem", use the
following commands:

```
$ vagrant plugin uninstall vagrant-parallels
$ vagrant plugin install pkg/vagrant-parallels-<version>.gem
```

Now that you have your own plugin installed, check it with the command
`vagrant plugin list`

### Sending a Pull Request
If you're ready to send your changes, please follow the next steps:

1. Fork the 'vagrant-parallels' repository and ad it as a new remote (`git add
remote my-fork <fork_url>`)
2. Create a branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Added a sweet feature"`)
4. Push the branch to your fork (`git push fork my-new-feature`)
5. Create a pull request from your `my-new-feature` branch into `master` of
`vagrant-parallels` repo

### Acceptance Tests

Vagrant also comes with an acceptance test suite that does black-box
tests of various Vagrant components. Note that these tests are **extremely
slow** because actual VMs are spun up and down. The full test suite can
take hours.

To run the acceptance test suite, first copy `vagrant-spec.config.example.rb`
to `vagrant-spec.config.rb` and modify it to valid values. The places you
should fill in are clearly marked. Highly recommend to download a box and
specify a local path to it.

Run acceptance tests:

```
$ bundle exec rake acceptance:run
...
```

### Releasing a New Provider Version

_Note: Only the owners of `vagrant-parallels` gem on https://rubygems.org are permitted
to release new versions._

1. Build and test the new gem version (see details above):
```
$ bundle exec rake build
```

2. Update the gem version in `./lib/vagrant-parallels/version.rb`

3. Update change log in `./CHANGELOG.md`

4. Commit those changes and also tag the release with the version:
```sh
$ git tag vX.Y.Z
$ git push --tags
```

4. Push a new gem version to rubygems.org:
```sh
$ gem push ./pkg/vagrant-parallels-<version>.gem
```

5. Create a new Release on Github from the newly pushed tag: https://github.com/Parallels/vagrant-parallels/tags.
   More info on the doc page: [Managing releases in a repository](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
