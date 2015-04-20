source 'http://rubygems.org'

group :plugins do
  # Specify your gem's dependencies in vagrant-parallels.gemspec
  gemspec
end

group :development do
  # We depend on Vagrant for development, but we don't add it as a
  # gem dependency because we expect to be installed within the
  # Vagrant environment itself using `vagrant plugin`.
  gem 'vagrant', git: 'git://github.com/mitchellh/vagrant.git', tag: 'v1.7.2'
  gem 'vagrant-spec', git: 'git://github.com/mitchellh/vagrant-spec.git'
end
