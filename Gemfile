source 'http://rubygems.org'

# Specify your gem's dependencies in vagrant-parallels.gemspec
gemspec

group :development do
  # We depend on Vagrant for development, but we don't add it as a
  # gem dependency because we expect to be installed within the
  # Vagrant environment itself using `vagrant plugin`.
  gem 'vagrant', :git => 'git://github.com/mitchellh/vagrant.git', :tag => 'v1.4.1'
  gem 'vagrant-spec', git: "https://github.com/mitchellh/vagrant-spec.git"
  gem 'debugger-xml'
  gem 'pry'
end
