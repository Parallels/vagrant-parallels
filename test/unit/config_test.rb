require_relative "../unit/base"

require VagrantPlugins::Parallels.source_root.join('lib/vagrant-parallels/config')

describe VagrantPlugins::Parallels::Config do

  context "defaults" do
    before { subject.finalize! }

    its(:check_guest_tools) { should be_true }
    its(:name) { should be_nil }

    it "should have one Shared adapter" do
      expect(subject.network_adapters).to eql({
        0 => [:shared, {}],
      })
    end
  end

  describe "memory=" do
    it "configures memory size (in Mb)" do
      subject.memory=(1024)
      expect(subject.customizations).to include(["pre-boot", ["set", :id, "--memsize", '1024']])
    end
  end

  describe "cpus=" do
    it "configures count of cpus" do
      subject.cpus=('4')
      expect(subject.customizations).to include(["pre-boot", ["set", :id, "--cpus", 4]])
    end
  end

  describe "#network_adapter" do
    it "configures additional adapters" do
      subject.network_adapter(2, :bridged, auto_config: true)
      expect(subject.network_adapters[2]).to eql(
        [:bridged, auto_config: true])
    end
  end
end
