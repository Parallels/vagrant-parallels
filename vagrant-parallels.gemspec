# coding: utf-8
$:.unshift File.expand_path('../lib', __FILE__)
require 'vagrant-parallels/version'

Gem::Specification.new do |spec|
  spec.name          = 'vagrant-parallels'
  spec.version       = VagrantPlugins::Parallels::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Mikhail Zholobov', 'Youssef Shahin']
  spec.email         = ['legal90@gmail.com', 'yshahin@gmail.com']
  spec.summary       = %q{Parallels provider for Vagrant.}
  spec.description   = %q{Enables Vagrant to manage Parallels virtual machines.}
  spec.homepage      = 'https://github.com/Parallels/vagrant-parallels'
  spec.license       = 'MIT'

  spec.required_rubygems_version = '>= 1.3.6'
  spec.rubyforge_project         = 'vagrant-parallels'

  spec.add_dependency 'nokogiri'

  # Constraint rake to properly handle deprecated method usage
  # from within rspec
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.11'
  spec.add_development_dependency 'rspec-its', '~> 1.3.0'
  spec.add_development_dependency 'webrick', '~> 1.8.0'

  spec.files = Dir['lib/**/*', 'locales/**/*', 'README.md', 'CHANGELOG.md', 'LICENSE.txt']
  spec.require_path = 'lib'
end
