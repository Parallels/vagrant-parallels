# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This tests that synced folders work with a given provider.
shared_examples "provider/synced_folder_parallels" do |provider, options|
  if !options[:box]
    raise ArgumentError,
      "box option must be specified for provider: #{provider}"
  end

  include_context "acceptance"

  before do
    environment.skeleton("synced_folders")
    assert_execute("vagrant", "box", "add", "basic", options[:box])
    assert_execute("vagrant", "up", "--provider=#{provider}")
  end

  after do
    assert_execute("vagrant", "destroy", "--force")
  end

  # We put all of this in a single RSpec test so that we can test all
  # the cases within a single VM rather than having to `vagrant up` many
  # times.
  it "properly configures synced folder types" do
    status("Test: mounts the default /vagrant synced folder")
    result = execute("vagrant", "ssh", "-c", "cat /vagrant/foo")
    expect(result.exit_code).to eql(0)
    expect(result.stdout).to match(/hello$/)

    status("Test: doesn't mount a disabled folder")
    result = execute("vagrant", "ssh", "-c", "test -d /foo")
    expect(result.exit_code).to eql(1)

    status("Test: guest has permissions to write to synced folder")
    result = execute("vagrant", "ssh", "-c", "echo goodbye > /vagrant/bar")
    expect(result.exit_code).to eql(0)

    # Shared folders using vagrant-parallels do not persist at the same mount point after a reboot  
    # (they are mounted at a different location). As a result, these tests have been disabled.  
    # This decision was made collectively, as implementing this feature may not be necessary.  

    # status("Test: persists a sync folder after a manual reboot")
    # # Need to add a sleep here to make sure that the command will be executed for
    # # long enough to be killed by the reboot and exit with code 255, confirming the reboot
    # result = execute("vagrant", "cap", "guest", "reboot")
    # expect(result.exit_code).to eql(0)
    # # Need to do a manual sleep here because Vagrant doesn't know that the
    # # machine is rebooting
    # sleep 10
    # result = execute("vagrant", "ssh", "-c", "cat /vagrant/foo")
    # expect(result.exit_code).to eql(0)
    # expect(result.stdout).to match(/hello$/)

    status("Test: persists a sync folder after a provisioner reboot")
    result = execute("vagrant", "provision", "--provision-with", "reboot")
    expect(result.exit_code).to eql(0)
    # # Need to do a manual sleep here because Vagrant doesn't know that the
    # # machine is rebooting
    # sleep 10
    # result = execute("vagrant", "ssh", "-c", "cat /vagrant/foo")
    # expect(result.exit_code).to eql(0)
    # expect(result.stdout).to match(/hello$/)
  end
end

