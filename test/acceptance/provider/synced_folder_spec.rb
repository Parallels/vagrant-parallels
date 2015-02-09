# This tests that synced folders work with a given provider.
shared_examples "provider/synced_folder" do |provider, options|
  if !options[:box]
    raise ArgumentError,
      "box option must be specified for provider: #{provider}"
  end

  include_context "acceptance"

  before do
    environment.skeleton("synced_folder")
    assert_execute("vagrant", "box", "add", "basic", options[:box])
    assert_execute("vagrant", "up", "--provider=#{provider}")
  end

  after do
    assert_execute("vagrant", "destroy", "--force")
  end

  it "properly configures synced folder types" do
    status("Test: mounts the default /vagrant synced folder")
    result = execute("vagrant", "ssh", "-c", "cat /vagrant/foo")
    expect(result.exit_code).to eql(0)
    expect(result.stdout).to match(/hello$/)
  end
end
