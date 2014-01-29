require_relative "../base"

describe VagrantPlugins::Parallels::Driver::PrlCtl do
  include_context "parallels"

  subject { VagrantPlugins::Parallels::Driver::PrlCtl.new(uuid) }

  describe "compact" do
    it "compacts the VM disk images" do
      pending "Should have possibility to compact more than one hdd"
    end
  end

  describe "create_host_only_network" do
    it "creates host-only NIC"
  end

  describe "export" do
    tpl_name = "new_template_name"
    tpl_uuid = "12345-hfgs-3456-hste"

    it "exports VM to template" do
      subject.stub(:read_settings).with(tpl_name).
        and_return({"ID" => tpl_uuid})

      subprocess.should_receive(:execute).
        with("prlctl", "clone", uuid, "--name", an_instance_of(String), "--template", "--dst",
             an_instance_of(String), an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "The VM has been successfully cloned"))
      subject.export("/path/to/template", tpl_name).should == tpl_uuid
    end
  end

  describe "clear_shared_folders" do
    shf_hash = {"enabled" => true, "shf_name_1" => {}, "shf_name_2" => {}}
    it "deletes every shared folder assigned to the VM" do
      subject.stub(:read_settings).and_return({"Host Shared Folders" => shf_hash})

      subprocess.should_receive(:execute).exactly(2).times.
        with("prlctl", "set", uuid, "--shf-host-del", an_instance_of(String), an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "Shared folder deleted"))
      subject.clear_shared_folders
    end
  end

  describe "halt" do
    it "stops the VM" do
      subprocess.should_receive(:execute).
        with("prlctl", "stop", uuid, an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "VM has been halted gracefully"))
      subject.halt
    end

    it "stops the VM force" do
      subprocess.should_receive(:execute).
        with("prlctl", "stop", uuid, "--kill", an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "VM has been halted forcibly"))
      subject.halt(force=true)
    end
  end

  describe "mac_in_use?" do
    vm_1 = {
      'Hardware' => {
        'net0' => {'mac' => '001C42BB5901'},
        'net1' => {'mac' => '001C42BB5902'},
      }
    }
    vm_2 = {
      'Hardware' => {
        'net0' => {'mac' => '001C42BB5903'},
        'net1' => {'mac' => '001C42BB5904'},
      }
    }

    it "checks the MAC address is already in use" do
      subject.stub(:read_all_info).and_return([vm_1, vm_2])

      subject.mac_in_use?('00:1c:42:bb:59:01').should be_true
      subject.mac_in_use?('00:1c:42:bb:59:02').should be_false
      subject.mac_in_use?('00:1c:42:bb:59:03').should be_true
      subject.mac_in_use?('00:1c:42:bb:59:04').should be_false
    end
  end

  describe "set_name" do
    it "sets new name for the VM" do
      subprocess.should_receive(:execute).
        with("prlctl", "set", uuid, '--name', an_instance_of(String), an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "Settings applied"))

      subject.set_name('new_vm_name')
    end
  end

  describe "set_mac_address" do
    it "sets base MAC address to the Shared network adapter" do
      subprocess.should_receive(:execute).exactly(2).times.
        with("prlctl", "set", uuid, '--device-set', 'net0', '--type', 'shared', '--mac',
           an_instance_of(String), an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "Settings applied"))

      subject.set_mac_address('001C42DD5902')
      subject.set_mac_address('auto')
    end
  end

  describe "start" do
    it "starts the VM" do
      subprocess.should_receive(:execute).
        with("prlctl", "start", uuid, an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "VM started"))
      subject.start
    end
  end

  describe "suspend" do
    it "suspends the VM" do
      subprocess.should_receive(:execute).
        with("prlctl", "suspend", uuid, an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "VM suspended"))
      subject.suspend
    end
  end

  describe "unregister" do
    it "suspends the VM" do
      subprocess.should_receive(:execute).
        with("prlctl", "unregister", an_instance_of(String), an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "Specified VM unregistered"))
      subject.unregister("template_or_vm_uuid")
    end
  end

  describe "version" do
    it "parses the version from output" do
      subject.version.should match(/(#{parallels_version}[\d\.]+)/)
    end

    it "rises ParallelsInstallIncomplete exception when output is invalid" do
      subprocess.should_receive(:execute).
        with("prlctl", "--version", an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "Some incorrect value has been returned!"))
      expect { subject.version }.
        to raise_error(VagrantPlugins::Parallels::Errors::ParallelsInstallIncomplete)
    end
  end
end
