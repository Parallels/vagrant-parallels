require 'rake/testtask'
require 'rspec/core/rake_task'

namespace :test do
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = "test/unit/**/*_test.rb"
  end

  RSpec::Core::RakeTask.new(:acceptance) do |t|
    t.pattern = "test/acceptance/**/*_test.rb"
  end
end
