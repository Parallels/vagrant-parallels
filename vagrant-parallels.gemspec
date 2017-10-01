# coding: utf-8
$:.unshift File.expand_path('../lib', __FILE__)
require 'vagrant-parallels/version'

Gem::Specification.new do |spec|
  spec.name          = 'vagrant-parallels'
  spec.version       = VagrantPlugins::Parallels::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Mikhail Zholobov', 'Youssef Shahin']
  spec.email         = ['mzholobov@parallels.com', 'yshahin@gmail.com']
  spec.summary       = %q{Parallels provider for Vagrant.}
  spec.description   = %q{Enables Vagrant to manage Parallels virtual machines.}
  spec.homepage      = 'http://github.com/Parallels/vagrant-parallels'
  spec.license       = 'MIT'

  spec.required_rubygems_version = '>= 1.3.6'
  spec.rubyforge_project         = 'vagrant-parallels'

  spec.add_dependency 'nokogiri'

  # Constraint rake to properly handle deprecated method usage
  # from within rspec
  spec.add_development_dependency 'rake', '~> 11.3.0'
  spec.add_development_dependency 'rspec', '~> 3.5.0'
  spec.add_development_dependency 'rspec-its', '~> 1.2.0'

  spec.files = Dir['lib/**/*', 'locales/**/*', 'README.md', 'CHANGELOG.md', 'LICENSE.txt']
  spec.require_path = 'lib'
end
