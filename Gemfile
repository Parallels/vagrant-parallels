source 'https://rubygems.org'

group :plugins do
  # Specify your gem's dependencies in vagrant-parallels.gemspec
  gemspec
end

group :development do
  # We depend on Vagrant for development, but we don't add it as a
  # gem dependency because we expect to be installed within the
  # Vagrant environment itself using `vagrant plugin`.
  gem 'vagrant', git: 'https://github.com/hashicorp/vagrant.git', tag: 'v2.3.4'

  # TODO: Switch back to the upstream from `hashicorp` org when this PR is merged:
  # https://github.com/hashicorp/vagrant-spec/pull/56
  gem 'vagrant-spec', git: 'https://github.com/legal90/vagrant-spec.git', branch: 'fix-ruby-3'
end
