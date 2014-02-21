shared_examples "parallels desktop driver" do |options|
  before do
    raise ArgumentError, "Need parallels context to use these shared examples." unless defined? parallels_context
  end

  # Accessor to the delegate object
  let(:driver) { subject.instance_variable_get("@driver") }

  describe "compact" do
    settings = {"Hardware" => {"hdd0" => {"image" => "/path/to/disk0.hdd"},
                               "hdd1" => {"image" => "/path/to/disk1.hdd"}}}
    it "compacts the VM disk drives" do
      driver.should_receive(:read_settings).and_return(settings)

      subprocess.should_receive(:execute).exactly(2).times.
        with("prl_disk_tool", 'compact', '--hdd', /^\/path\/to\/disk(0|1).hdd$/,
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.compact(uuid)
    end
  end

  describe "clear_shared_folders" do
    it "deletes every shared folder assigned to the VM" do
      subprocess.should_receive(:execute).at_least(2).times.
        with("prlctl", "set", uuid, "--shf-host-del", an_instance_of(String),
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.clear_shared_folders
    end
  end

  describe "create_host_only_network" do
    let(:hostonly_iface) {'vnic12'}
    it "creates host-only NIC with dhcp server configured" do
      vnic_opts = {
        :name => 'vagrant_vnic8',
        :adapter_ip => '11.11.11.11',
        :netmask    => '255.255.252.0',
        :dhcp => {
          :ip => '11.11.11.11',
          :lower => '11.11.8.1',
          :upper => '11.11.11.254'
        }
      }

      subprocess.should_receive(:execute).
        with("prlsrvctl", "net", "add", vnic_opts[:name],
             "--type", "host-only", an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      subprocess.should_receive(:execute).
        with("prlsrvctl", "net", "set", vnic_opts[:name],
             "--ip", "#{vnic_opts[:adapter_ip]}/#{vnic_opts[:netmask]}",
             "--dhcp-ip", vnic_opts[:dhcp][:ip],
             "--ip-scope-start", vnic_opts[:dhcp][:lower],
             "--ip-scope-end", vnic_opts[:dhcp][:upper], an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      interface = subject.create_host_only_network(vnic_opts)

      interface.should include(:name => vnic_opts[:name])
      interface.should include(:ip => vnic_opts[:adapter_ip])
      interface.should include(:netmask => vnic_opts[:netmask])
      interface.should include(:dhcp => vnic_opts[:dhcp])
      interface.should include(:bound_to => hostonly_iface)
      interface[:bound_to].should =~ /^(vnic(\d+))$/
    end

    it "creates host-only NIC without dhcp" do
      vnic_options = {
        :name => 'vagrant_vnic3',
        :adapter_ip => '22.22.22.22',
        :netmask    => '255.255.254.0',
      }

      subprocess.should_receive(:execute).
        with("prlsrvctl", "net", "add", vnic_options[:name],
             "--type", "host-only", an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      subprocess.should_receive(:execute).
        with("prlsrvctl", "net", "set", vnic_options[:name],
             "--ip", "#{vnic_options[:adapter_ip]}/#{vnic_options[:netmask]}",
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      interface = subject.create_host_only_network(vnic_options)

      interface.should include(:name => vnic_options[:name])
      interface.should include(:ip => vnic_options[:adapter_ip])
      interface.should include(:netmask => vnic_options[:netmask])
      interface.should include(:dhcp => nil)
      interface.should include(:bound_to => hostonly_iface)
      interface[:bound_to].should =~ /^(vnic(\d+))$/
    end
  end

  describe "delete" do
    it "deletes the VM" do
      subprocess.should_receive(:execute).
        with("prlctl", "delete", uuid, an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.delete
    end
  end

  describe "delete_disabled_adapters" do
    it "deletes disabled networks adapters from VM config" do
      settings = {"Hardware" => {"net0" => {"enabled" => false},
                                 "net1" => {"enabled" => false}}}
      driver.should_receive(:read_settings).and_return(settings)
      subprocess.should_receive(:execute).exactly(2).times.
        with("prlctl", "set", uuid, "--device-del", /^net(0|1)$/,
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.delete_disabled_adapters
    end
  end

  describe "export" do
    tpl_name = "Some_Template_Name"
    tpl_uuid = "1234-some-template-uuid-5678"

    it "exports VM to template" do
      subprocess.should_receive(:execute).
        with("prlctl", "clone", uuid, "--name", an_instance_of(String),
             "--template", "--dst", an_instance_of(String),
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.export("/path/to/template", tpl_name).should == tpl_uuid
    end
  end

  describe "halt" do
    it "stops the VM" do
      subprocess.should_receive(:execute).
        with("prlctl", "stop", uuid, an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.halt
    end

    it "stops the VM force" do
      subprocess.should_receive(:execute).
        with("prlctl", "stop", uuid, "--kill", an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.halt(force=true)
    end
  end

  describe "mac_in_use?" do
    before do
      vms_info = [{"Hardware" => {"net0" => {"mac" => "00AABBCC01"},
                                  "net1" => {"mac" => "00AABBCC02"}}},
                  {"Hardware" => {"net0" => {"mac" => "00AABBCC03"},
                                  "net1" => {"mac" => "00AABBCC04"}}}]
      driver.should_receive(:read_vms_info).and_return(vms_info)
    end

    it { subject.mac_in_use?('00:AA:BB:CC:01').should be_true }
    it { subject.mac_in_use?('00:AA:BB:CC:02').should be_false }
    it { subject.mac_in_use?('00:AA:BB:CC:03').should be_true }
    it { subject.mac_in_use?('00:AA:BB:CC:04').should be_false }

  end

  describe "read_settings" do
    it "returns a hash with detailed info about the VM" do
      subject.read_settings.should be_kind_of(Hash)
      subject.read_settings.should include("ID" => uuid)
      subject.read_settings.should include("Hardware")
      subject.read_settings.should include("GuestTools")
    end
  end

  describe "read_vms" do
    it "returns the list of all registered VMs and templates" do
      subject.read_vms.should be_kind_of(Hash)
      subject.read_vms.should have_at_least(2).items
      subject.read_vms.should include(vm_name => uuid)
    end
  end

  describe "read_vms_info" do
    it "returns detailed info about all registered VMs and templates" do
      subject.read_vms_info.should be_kind_of(Array)
      subject.read_vms_info.should have_at_least(2).items

      # It should include info about current VM
      vm_settings = driver.send(:read_settings)
      subject.read_vms_info.should include(vm_settings)
    end
  end

  describe "set_mac_address" do
    it "sets base MAC address to the Shared network adapter" do
      subprocess.should_receive(:execute).exactly(2).times.
        with("prlctl", "set", uuid, '--device-set', 'net0', '--type', 'shared',
             '--mac', an_instance_of(String), an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      subject.set_mac_address('001C42DD5902')
      subject.set_mac_address('auto')
    end
  end

  describe "set_name" do
    it "sets new name for the VM" do
      subprocess.should_receive(:execute).
        with("prlctl", "set", uuid, '--name', an_instance_of(String),
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      subject.set_name('new_vm_name')
    end
  end

  describe "start" do
    it "starts the VM" do
      subprocess.should_receive(:execute).
        with("prlctl", "start", uuid, an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.start
    end
  end

  describe "suspend" do
    it "suspends the VM" do
      subprocess.should_receive(:execute).
        with("prlctl", "suspend", uuid, an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.suspend
    end
  end

  describe "unregister" do
    it "suspends the VM" do
      subprocess.should_receive(:execute).
        with("prlctl", "unregister", an_instance_of(String),
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
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
        and_return(subprocess_result(exit_code: 0))
      expect { subject.version }.
        to raise_error(VagrantPlugins::Parallels::Errors::ParallelsInvalidVersion)
    end
  end
end
