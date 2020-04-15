source 'https://rubygems.org'

group :plugins do
  # Specify your gem's dependencies in vagrant-parallels.gemspec
  gemspec
end

group :development do
  # We depend on Vagrant for development, but we don't add it as a
  # gem dependency because we expect to be installed within the
  # Vagrant environment itself using `vagrant plugin`.
  gem 'vagrant', git: 'https://github.com/mitchellh/vagrant.git'
  gem 'vagrant-spec', git: 'https://github.com/mitchellh/vagrant-spec.git'
end
