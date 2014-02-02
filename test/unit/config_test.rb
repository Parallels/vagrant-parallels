require_relative "../unit/base"

require VagrantPlugins::Parallels.source_root.join('lib/vagrant-parallels/config')

describe VagrantPlugins::Parallels::Config do

  context "defaults" do
    before { subject.finalize! }

    it "should have one Shared adapter" do
      expect(subject.network_adapters).to eql({
        0 => [:shared, []],
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
end
