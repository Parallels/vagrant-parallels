# coding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)
require 'vagrant-parallels/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-parallels"
  spec.version       = VagrantPlugins::Parallels::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Mikhail Zholobov", "Youssef Shahin"]
  spec.email         = ["mzholobov@parallels.com", "yshahin@gmail.com"]
  spec.summary       = %q{Parallels provider for Vagrant.}
  spec.description   = %q{Enables Vagrant to manage Parallels virtual machines.}
  spec.homepage      = "http://github.com/Parallels/vagrant-parallels"
  spec.license       = "MIT"

  spec.required_rubygems_version = ">= 1.3.6"
  spec.rubyforge_project         = "vagrant-parallels"

  spec.add_development_dependency "bundler", ">= 1.5.2", "< 1.7.0" 
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rspec", "~> 2.14.0"
  spec.add_development_dependency "i18n-tasks", "~> 0.3.9"

  # The following block of code determines the files that should be included
  # in the gem. It does this by reading all the files in the directory where
  # this gemspec is, and parsing out the ignored files from the gitignore.
  # Note that the entire gitignore(5) syntax is not supported, specifically
  # the "!" syntax, but it should mostly work correctly.
  root_path = File.dirname(__FILE__)
  all_files = Dir.chdir(root_path) { Dir.glob("**/{*,.*}") }
  all_files.reject! { |file| [".", ".."].include?(File.basename(file)) }
  gitignore_path = File.join(root_path, ".gitignore")
  gitignore = File.readlines(gitignore_path)
  gitignore.map! { |line| line.chomp.strip }
  gitignore.reject! { |line| line.empty? || line =~ /^(#|!)/ }

  unignored_files = all_files.reject do |file|
    # Ignore any directories, the gemspec only cares about files
    next true if File.directory?(file)

    # Ignore any paths that match anything in the gitignore. We do
    # two tests here:
    #
    # - First, test to see if the entire path matches the gitignore.
    # - Second, match if the basename does, this makes it so that things
    # like '.DS_Store' will match sub-directories too (same behavior
    # as git).
    #
    gitignore.any? do |ignore|
      File.fnmatch(ignore, file, File::FNM_PATHNAME) ||
        File.fnmatch(ignore, File.basename(file), File::FNM_PATHNAME)
    end
  end

  spec.files = unignored_files
  spec.executables = unignored_files.map { |f| f[/^bin\/(.*)/, 1] }.compact
  spec.require_path = "lib"
end
