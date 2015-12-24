shared_examples 'parallels desktop driver' do |options|
  before do
    raise ArgumentError, 'Need parallels context to use these shared examples.' unless defined? parallels_context
  end

  describe 'compact' do
    settings = {'Hardware' => {'hdd0' => {'image' => '/path/to/disk0.hdd'},
                               'hdd1' => {'image' => '/path/to/disk1.hdd'}}}
    it 'compacts the VM disk drives' do
      driver.should_receive(:read_settings).and_return(settings)

      subprocess.should_receive(:execute).exactly(2).times.
        with('prl_disk_tool', 'compact', '--hdd', /^\/path\/to\/disk(0|1).hdd$/,
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.compact(uuid)
    end
  end

  describe 'clear_shared_folders' do
    it 'deletes every shared folder assigned to the VM' do
      subprocess.should_receive(:execute).at_least(2).times.
        with('prlctl', 'set', uuid, '--shf-host-del', an_instance_of(String),
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.clear_shared_folders
    end
  end

  describe 'create_host_only_network' do
    let(:hostonly_iface) {'vnic12'}
    it 'creates host-only NIC with dhcp server configured' do
      vnic_opts = {
        network_id: 'vagrant_vnic8',
        adapter_ip: '11.11.11.11',
        netmask:    '255.255.252.0',
        dhcp:       {
          ip:    '11.11.11.11',
          lower: '11.11.8.1',
          upper: '11.11.11.254'
        }
      }

      subprocess.should_receive(:execute).
        with('prlsrvctl', 'net', 'add', vnic_opts[:network_id],
             '--type', 'host-only', an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      subprocess.should_receive(:execute).
        with('prlsrvctl', 'net', 'set', vnic_opts[:network_id],
             '--ip', "#{vnic_opts[:adapter_ip]}/#{vnic_opts[:netmask]}",
             '--dhcp-ip', vnic_opts[:dhcp][:ip],
             '--ip-scope-start', vnic_opts[:dhcp][:lower],
             '--ip-scope-end', vnic_opts[:dhcp][:upper], an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      interface = subject.create_host_only_network(vnic_opts)

      interface.should include(:ip => vnic_opts[:adapter_ip])
      interface.should include(:netmask => vnic_opts[:netmask])
      interface.should include(:dhcp => vnic_opts[:dhcp])
      # TODO: implement nicer tests for all supported PD versions
      # interface.should include(:name => hostonly_iface)
      # interface[:name].should =~ /^(vnic(\d+))$/
    end

    it 'creates host-only NIC without dhcp' do
      vnic_options = {
        network_id: 'vagrant_vnic3',
        adapter_ip: '22.22.22.22',
        netmask:    '255.255.254.0',
      }

      subprocess.should_receive(:execute).
        with('prlsrvctl', 'net', 'add', vnic_options[:network_id],
             '--type', 'host-only', an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      subprocess.should_receive(:execute).
        with('prlsrvctl', 'net', 'set', vnic_options[:network_id],
             '--ip', "#{vnic_options[:adapter_ip]}/#{vnic_options[:netmask]}",
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      interface = subject.create_host_only_network(vnic_options)

      interface.should include(:ip => vnic_options[:adapter_ip])
      interface.should include(:netmask => vnic_options[:netmask])
      interface.should include(:dhcp => nil)
      # TODO: implement nicer tests for all supported PD versions
      # interface.should include(:name => hostonly_iface)
      # interface[:name].should =~ /^(vnic(\d+))$/
    end
  end

  describe 'delete' do
    it 'deletes the VM' do
      subprocess.should_receive(:execute).
        with('prlctl', 'delete', uuid, an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.delete
    end
  end

  describe 'delete_disabled_adapters' do
    it 'deletes disabled networks adapters from VM config' do
      settings = {'Hardware' => {'net0' => {'enabled' => false},
                                 'net1' => {'enabled' => false}}}
      driver.should_receive(:read_settings).and_return(settings)
      subprocess.should_receive(:execute).exactly(2).times.
        with('prlctl', 'set', uuid, '--device-del', /^net(0|1)$/,
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.delete_disabled_adapters
    end
  end

  describe 'clone_vm' do
    it 'clones VM to the new one' do
      subprocess.should_receive(:execute).
        with('prlctl', 'clone', tpl_uuid, '--name', an_instance_of(String),
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.clone_vm(tpl_uuid)
    end

    it 'clones VM to the exported VM' do
      subprocess.should_receive(:execute).
        with('prlctl', 'clone', uuid, '--name', an_instance_of(String),
             '--dst', an_instance_of(String), an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.clone_vm(uuid, {dst: '/path/to/template'})
    end
  end

  describe 'halt' do
    it 'stops the VM' do
      subprocess.should_receive(:execute).
        with('prlctl', 'stop', uuid, an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.halt
    end

    it 'stops the VM force' do
      subprocess.should_receive(:execute).
        with('prlctl', 'stop', uuid, '--kill', an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.halt(force=true)
    end
  end

  describe 'read_guest_tools_state' do
    let(:tools_state) {'outdated'}

    it 'returns Guest Tools state as a symbol' do
      subject.read_guest_tools_state.should be(:outdated)
    end

    it "returns :not_installed if Guest Tools state can't be reached" do
      driver.should_receive(:read_settings).and_return(exit_code: 0)
      subject.read_guest_tools_state.should be(:not_installed)
    end
  end

  describe 'read_guest_tools_iso_path' do
    before do
      subprocess.stub(:execute).
        with('mdfind', /^kMDItemCFBundleIdentifier ==/, an_instance_of(Hash)).
        and_return(subprocess_result(stdout: '/Applications/Parallels Desktop.app'))
    end

    it 'returns a valid path to the ISO' do
      File.stub(:exist?).and_return(true)
      iso_path = subject.read_guest_tools_iso_path('linux')
      iso_path.should be_kind_of(String)
      iso_path.should match(/prl-tools-lin\.iso$/)
    end

    it 'raises an exception if ISO file does not exists' do
      File.stub(:exist?).and_return(false)
      expect { subject.read_guest_tools_iso_path('windows') }.
        to raise_error(VagrantPlugins::Parallels::Errors::ParallelsToolsIsoNotFound)
    end

    it 'returns nil if guest OS is unsupported or invalid' do
      subject.read_guest_tools_iso_path('').should be_nil
      subject.read_guest_tools_iso_path('bolgenos').should be_nil
    end
  end

  describe 'read_mac_addresses' do
    it 'returns MAC addresses of all network interface cards' do
      subject.read_mac_addresses.should be_kind_of(Array)
      subject.read_mac_addresses.should include('001C42B4B074')
      subject.read_mac_addresses.should include('001C42B4B090')
    end
  end

  describe 'read_settings' do
    it 'returns a hash with detailed info about the VM' do
      subject.read_settings.should be_kind_of(Hash)
      subject.read_settings.should include('ID' => uuid)
      subject.read_settings.should include('Hardware')
      subject.read_settings.should include('GuestTools')
    end
  end

  describe 'read_vm_option' do
    it 'returns stripped value' do
      subprocess.stub(:execute).
        with('prlctl', 'list', uuid, '--no-header', '-o', an_instance_of(String),
             an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "opt_val \n"))

      subject.read_vm_option('supported_option').should == 'opt_val'
    end

    it 'raises an exception in option is not available' do
      subprocess.stub(:execute).
        with('prlctl', 'list', uuid, '--no-header', '-o', an_instance_of(String),
             an_instance_of(Hash)).
        and_return(subprocess_result(stdout: " \n"))

      expect { subject.read_vm_option('invalid_option') }.
        to raise_error(VagrantPlugins::Parallels::Errors::ParallelsVMOptionNotFound)
    end
  end

  describe 'read_vms' do
    it 'returns the list of all registered VMs and templates' do
      subject.read_vms.should be_kind_of(Hash)
      subject.read_vms.should have_at_least(2).items
      subject.read_vms.should include(vm_name => uuid)
    end
  end

  describe 'read_vms_info' do
    it 'returns detailed info about all registered VMs and templates' do
      subject.read_vms_info.should be_kind_of(Array)
      subject.read_vms_info.should have_at_least(2).items

      # It should include info about current VM
      vm_settings = driver.send(:read_settings)
      subject.read_vms_info.should include(vm_settings)
    end
  end

  describe 'register' do
    it 'registers specified virtual machine or template' do
      subprocess.should_receive(:execute).
        with('prlctl', 'register', an_instance_of(String), an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      subject.register('/path/to/vm_image.pvm')
    end
  end

  describe 'set_name' do
    it 'sets new name for the VM' do
      subprocess.should_receive(:execute).
        with('prlctl', 'set', uuid, '--name', an_instance_of(String),
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      subject.set_name(uuid, 'new_vm_name')
    end
  end

  describe 'ssh_ip' do
    let(:content) {'10.200.0.100="1394546410,1800,001c420000ff,01001c420000ff
                    10.200.0.99="1394547632,1800,001c420000ff,01001c420000ff"'}

    it 'returns an IP address assigned to the specified MAC' do
      driver.should_receive(:read_mac_address).and_return('001C420000FF')
      File.should_receive(:open).with(an_instance_of(String)).
        and_return(StringIO.new(content))

      subject.ssh_ip.should == '10.200.0.99'
    end

    it 'rises DhcpLeasesNotAccessible exception when file is not accessible' do
      File.stub(:open).and_call_original
      File.should_receive(:open).with(an_instance_of(String)).
        and_raise(Errno::EACCES)
      expect { subject.ssh_ip }.
        to raise_error(VagrantPlugins::Parallels::Errors::DhcpLeasesNotAccessible)
    end
  end

  describe 'start' do
    it 'starts the VM' do
      subprocess.should_receive(:execute).
        with('prlctl', 'start', uuid, an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.start
    end
  end

  describe 'suspend' do
    it 'suspends the VM' do
      subprocess.should_receive(:execute).
        with('prlctl', 'suspend', uuid, an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.suspend
    end
  end

  describe 'unregister' do
    it 'suspends the VM' do
      subprocess.should_receive(:execute).
        with('prlctl', 'unregister', an_instance_of(String),
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))
      subject.unregister('template_or_vm_uuid')
    end
  end

  describe 'version' do
    it 'parses the version from output' do
      subject.version.should match(/^#{parallels_version}.\d+\.\d+$/)
    end

    it 'raises an exception for unsupported version' do
      subprocess.should_receive(:execute).
        with('prlctl', '--version', an_instance_of(Hash)).
        and_return(subprocess_result(stdout: 'prlctl version 7.0.12345'))
      expect { subject.version }.
        to raise_error(VagrantPlugins::Parallels::Errors::ParallelsUnsupportedVersion)
    end

    it 'raises an exception for invalid version output' do
      subprocess.should_receive(:execute).
        with('prlctl', '--version', an_instance_of(Hash)).
        and_return(subprocess_result(stdout: 'prlctl version 1.2.foo.bar'))
      expect { subject.version }.
        to raise_error(VagrantPlugins::Parallels::Errors::ParallelsInvalidVersion)
    end
  end
end
