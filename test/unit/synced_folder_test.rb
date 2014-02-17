require "vagrant"
require_relative "base"

require VagrantPlugins::Parallels.source_root.join('lib/vagrant-parallels/synced_folder')

describe VagrantPlugins::Parallels::SyncedFolder do
  let(:machine) do
    double("machine").tap do |m|
    end
  end

  subject { described_class.new }

  describe "usable" do
    it "should be with parallels provider" do
      machine.stub(provider_name: :parallels)
      subject.should be_usable(machine)
    end

    it "should not be with another provider" do
      machine.stub(provider_name: :virtualbox)
      subject.should_not be_usable(machine)
    end
  end

  describe "prepare" do
    let(:driver) { double("driver") }

    before do
      machine.stub(driver: driver)
    end

    it "should share the folders" do
      pending
    end
  end
end
