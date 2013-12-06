require_relative "../base"

describe VagrantPlugins::Parallels::Driver::PrlCtl do
  include_context "parallels"

  let(:parallels_version) { "9" }

  subject { VagrantPlugins::Parallels::Driver::PrlCtl.new(uuid) }

  describe "version" do
    it "parses the version from the output" do
      subprocess.should_receive(:execute).
          with("prlctl", "--version", an_instance_of(Hash)).
          and_return(subprocess_result(stdout: "prlctl version 1.2.34567.987654"))

      subject.version.should == "1.2.34567.987654"
    end

    it "rises ParallelsInstallIncomplete exception when output is invalid" do
      subprocess.should_receive(:execute).
          with("prlctl", "--version", an_instance_of(Hash)).
          and_return(subprocess_result(stdout: "Incorrect value has been returned!"))

      expect { subject.version }.
        to raise_error(VagrantPlugins::Parallels::Errors::ParallelsInstallIncomplete)
    end
  end
end
