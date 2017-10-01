require 'rubygems'
require 'rspec/its'

# Require Vagrant itself so we can reference the proper
# classes to test.
require 'vagrant'
require 'vagrant-parallels'
require 'vagrant-spec/unit'

# Add the test directory to the load path
$:.unshift File.expand_path('../../', __FILE__)

# Load in helpers
require 'unit/support/shared/parallels_context'
require 'unit/support/shared/pd_driver_examples'

# Do not buffer output
$stdout.sync = true
$stderr.sync = true

# Configure RSpec
RSpec.configure do |c|
  c.expect_with :rspec
end
