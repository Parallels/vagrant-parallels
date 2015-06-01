require_relative "../base"

describe VagrantPlugins::Parallels::Driver::PD_9 do
  include_context "parallels"

  subject { VagrantPlugins::Parallels::Driver::Meta.new(uuid) }

  it_behaves_like "parallels desktop driver"

  describe "set_power_consumption_mode" do
    it "turns 'longer-battery-life' on" do
      subprocess.should_receive(:execute).
        with("prlctl", "set", uuid, "--longer-battery-life", "on",
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      subject.set_power_consumption_mode(true)
    end

    it "turns 'longer-battery-life' off" do
      subprocess.should_receive(:execute).
        with("prlctl", "set", uuid, "--longer-battery-life", "off",
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      subject.set_power_consumption_mode(false)
    end
  end

  describe "ssh_ip" do
    let(:content) {'10.200.0.100="1394546410,1800,001c420000ff,01001c420000ff
                    10.200.0.99="1394547632,1800,001c420000ff,01001c420000ff"'}

    it "returns an IP address assigned to the specified MAC" do
      driver.should_receive(:read_mac_address).and_return("001C420000FF")
      File.should_receive(:open).with(an_instance_of(String)).
        and_return(StringIO.new(content))

      subject.ssh_ip.should == "10.200.0.99"
    end

    it "rises DhcpLeasesNotAccessible exception when file is not accessible" do
      File.stub(:open).and_call_original
      File.should_receive(:open).with(an_instance_of(String)).
        and_raise(Errno::EACCES)
      expect { subject.ssh_ip }.
        to raise_error(VagrantPlugins::Parallels::Errors::DhcpLeasesNotAccessible)
    end
  end

end
