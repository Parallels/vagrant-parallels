require "vagrant"
require_relative "base"

require VagrantPlugins::Parallels.source_root.join("lib/vagrant-parallels/config")
require VagrantPlugins::Parallels.source_root.join('lib/vagrant-parallels/synced_folder')

describe VagrantPlugins::Parallels::SyncedFolder do
  let(:machine) do
    double("machine").tap do |m|
      m.stub(provider_config: VagrantPlugins::Parallels::Config.new)
      m.stub(provider_name: :parallels)
    end
  end

  subject { described_class.new }

  before do
    machine.provider_config.finalize!
  end

  describe "usable" do
    it "should be with parallels provider" do
      machine.stub(provider_name: :parallels)
      subject.should be_usable(machine)
    end

    it "should not be with another provider" do
      machine.stub(provider_name: :virtualbox)
      subject.should_not be_usable(machine)
    end

    it "should not be usable if not functional psf" do
      machine.provider_config.functional_psf = false
      expect(subject).to_not be_usable(machine)
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
