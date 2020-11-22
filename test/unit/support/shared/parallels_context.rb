shared_context 'parallels' do
  let(:parallels_context) { true                                     }
  let(:uuid)              { '1234-here-is-uuid-5678' }
  let(:parallels_version) { '12' }
  let(:subprocess)        { double('Vagrant::Util::Subprocess')      }
  let(:driver)            { subject.instance_variable_get('@driver') }

  let(:vm_name) {'VM_Name'}
  let(:tpl_uuid) {'1234-some-template-uuid-5678'}
  let(:tpl_name) {'Some_Template_Name'}
  let(:tools_state) {'installed'}
  let(:tools_version) {'12.0.18615.123456'}

  let(:vnic_options) do {
    name:       'vagrant_vnic6',
    adapter_ip: '11.11.11.11',
    netmask:    '255.255.252.0',
    dhcp:       {
      ip:    '11.11.11.11',
      lower: '11.11.8.1',
      upper: '11.11.11.254'
    }
  } end

  # this is a helper that returns a duck type suitable from a system command
  # execution; allows setting exit_code, stdout, and stderr in stubs.
  def subprocess_result(options={})
    defaults = {exit_code: 0, stdout: '', stderr: ''}
    double('subprocess_result', defaults.merge(options))
  end

  before do
    # Consider that 'prlctl' and 'prlsrvctl' binaries are available
    allow(Vagrant::Util::Which).to receive(:which).with('prlctl').and_return('prlctl')
    allow(Vagrant::Util::Which).to receive(:which).with('prlsrvctl').and_return('prlsrvctl')
    allow(Vagrant::Util::Which).to receive(:which).with('prl_disk_tool').and_return('prl_disk_tool')

    # Stub the platform, because we need unit test passed on any platform (Travis)
    allow(Vagrant::Util::Platform).to receive(:darwin?).and_return true

    # we don't want unit tests to ever run commands on the system; so we wire
    # in a double to ensure any unexpected messages raise exceptions
    stub_const('Vagrant::Util::Subprocess', subprocess)

    # drivers will blow up on instantiation if they cannot determine the
    # Parallels Desktop version, so wire this stub in automatically
    allow(subprocess).to receive(:execute).
      with('prlctl', '--version', an_instance_of(Hash)).
      and_return(subprocess_result(stdout: "prlctl version #{parallels_version}.0.0 (12345)"))

    # drivers will sould chek the Parallels Desktop edition, so wire this stub in automatically
    allow(subprocess).to receive(:execute).
      with('prlsrvctl', 'info', '--license', '--json', an_instance_of(Hash)).
      and_return(subprocess_result(stdout: '{"edition": "pro"}'))

    # drivers also call vm_exists? during init;
    allow(subprocess).to receive(:execute).
      with('prlctl', 'list', uuid, kind_of(Hash)).
      and_return(subprocess_result(exit_code: 0))

    # Returns detailed info about specified VM or all registered VMs
    # `prlctl list <vm_uuid> --info --no-header --json`
    # `prlctl list --all --info --no-header --json`
    allow(subprocess).to receive(:execute).
      with('prlctl', 'list', kind_of(String), '--info', '--no-header', '--json',
           kind_of(Hash)) do
      out = <<-eos
[
  {
    "ID": "#{uuid}",
    "Name": "#{vm_name}",
    "State": "stopped",
    "Home": "/path/to/#{vm_name}.pvm/",
    "GuestTools": {
      "state": "#{tools_state}",
      "version": "#{tools_version}"
    },
    "Hardware": {
      "cpu": {
        "cpus": 1
      },
      "memory": {
        "size": "512Mb"
      },
      "hdd0": {
        "enabled": true,
        "image": "/path/to/disk1.hdd"
      },
      "net0": {
        "enabled": true,
        "type": "shared",
        "mac": "001C42B4B074",
        "card": "e1000",
        "dhcp": "yes"
      },
      "net1": {
        "enabled": true,
        "type": "bridged",
        "iface": "vnic2",
        "mac": "001C42EC0068",
        "card": "e1000",
        "ips": "33.33.33.5/255.255.255.0 "
      }
    },
    "Host Shared Folders": {
      "enabled": true,
      "shared_folder_1": {
        "enabled": true,
        "path": "/path/to/shared/folder/1"
      },
      "shared_folder_2": {
        "enabled": true,
        "path": "/path/to/shared/folder/2"
      }
    }
  }
]
      eos
      subprocess_result(stdout: out)
    end

    # Returns detailed info about specified template or all registered templates
    # `prlctl list <tpl_uuid> --info --json --no-header --template`
    # `prlctl list --all --info --no-header --json --template`
    allow(subprocess).to receive(:execute).
      with('prlctl', 'list', kind_of(String), '--info', '--no-header', '--json',
           '--template', kind_of(Hash)) do
      out = <<-eos
[
  {
    "ID": "#{tpl_uuid}",
    "Name": "#{tpl_name}",
    "State": "stopped",
    "Home": "/path/to/#{tpl_name}.pvm/",
    "GuestTools": {
      "state": "#{tools_state}",
      "version": "#{tools_version}"
    },
    "Hardware": {
      "cpu": {
        "cpus": 1
      },
      "memory": {
        "size": "512Mb"
      },
      "hdd0": {
        "enabled": true,
        "image": "/path/to/harddisk.hdd"
      },
      "net0": {
        "enabled": true,
        "type": "shared",
        "mac": "001C42F6E500",
        "card": "e1000",
        "dhcp": "yes"
      },
      "net1": {
        "enabled": true,
        "type": "bridged",
        "iface": "vnic4",
        "mac": "001C42AB0071",
        "card": "e1000",
        "ips": "33.33.33.10/255.255.255.0 "
      }
    }
  }
]
      eos
      subprocess_result(stdout: out)
    end

    # Returns detailed info about virtual network interface
    # `prlsrvctl net info <net_name>, '--json'`
    allow(subprocess).to receive(:execute).
      with('prlsrvctl', 'net', 'info', kind_of(String), '--json',
           kind_of(Hash)) do
      out = <<-eos
{
  "Network ID": "#{vnic_options[:name]}",
  "Type": "host-only",
  "Parallels adapter": {
    "IP address": "#{vnic_options[:adapter_ip]}",
    "Subnet mask": "#{vnic_options[:netmask]}"
  },
  "DHCPv4 server": {
    "Server address": "#{vnic_options[:dhcp][:ip] || '10.37.132.1'}",
    "IP scope start address": "#{vnic_options[:dhcp][:lower] || '10.37.132.1'}",
    "IP scope end address": "#{vnic_options[:dhcp][:upper] || '10.37.132.254'}"
  }
}
      eos
      subprocess_result(stdout: out)
    end

    # Returns values of 'name' and 'uuid' options for all registered VMs
    # `prlctl list --all --no-header --json -o name,uuid`
    allow(subprocess).to receive(:execute).
      with('prlctl', 'list', '--all', '--no-header', '--json', '-o', 'name,uuid',
           kind_of(Hash)) do
      out = <<-eos
[
	{
		"name": "#{vm_name}",
		"uuid": "#{uuid}"
	}
]
      eos
      subprocess_result(stdout: out)
    end

    # Returns values of 'name' and 'uuid' options for all registered templates
    # `prlctl list --all --no-header --json -o name,uuid --template`
    allow(subprocess).to receive(:execute).
      with('prlctl', 'list', '--all', '--no-header', '--json', '-o', 'name,uuid',
           '--template', kind_of(Hash)) do
      out = <<-eos
[
	{
		"name": "#{tpl_name}",
		"uuid": "#{tpl_uuid}"
	}
]
      eos
      subprocess_result(stdout: out)
    end

    # Returns value of 'mac' options for the specified VM
    # `prlctl list --all --no-header -o mac`
    allow(subprocess).to receive(:execute).
      with('prlctl', 'list', kind_of(String), '--no-header', '-o', 'mac',
           kind_of(Hash)) do
      subprocess_result(stdout: "00:1C:42:B4:B0:74 00:1C:42:B4:B0:90\n")
    end

  end
end
