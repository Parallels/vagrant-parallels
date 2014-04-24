require_relative "../base"

describe VagrantPlugins::Parallels::Driver::PD_9 do
  include_context "parallels"
  let(:parallels_version) { "9" }

  let(:vm_name) {'VM_Name'}

  let(:tpl_uuid) {'1234-some-template-uuid-5678'}
  let(:tpl_name) {'Some_Template_Name'}

  let(:tools_version) {'9.0.23062.123456'}

  let(:hostonly_iface) {'vnic10'}

  let(:vnic_options) do {
    :name => 'vagrant_vnic6',
    :adapter_ip => '11.11.11.11',
    :netmask    => '255.255.252.0',
    :dhcp => {
      :ip => '11.11.11.11',
      :lower => '11.11.8.1',
      :upper => '11.11.11.254'
    }
  } end

  subject { VagrantPlugins::Parallels::Driver::Meta.new(uuid) }

  it_behaves_like "parallels desktop driver"

  before do
    # Returns short info about all registered VMs
    # `prlctl list --all --json`
    subprocess.stub(:execute).
      with("prlctl", "list", "--all", "--json", kind_of(Hash)) do
        out = <<-eos
[
  {
    "uuid": "#{uuid}",
    "status": "stopped",
    "name": "#{vm_name}"
  }
]
        eos
        subprocess_result(stdout: out)
    end

    # Returns short info about all registered templates
    # `prlctl list --all --json --template`
    subprocess.stub(:execute).
      with("prlctl", "list", "--all", "--json", "--template", kind_of(Hash)) do
        out = <<-eos
[
  {
    "uuid": "1234-some-template-uuid-5678",
    "name": "Some_Template_Name"
  }
]
        eos
        subprocess_result(stdout: out)
    end


    # Returns detailed info about specified VM or all registered VMs
    # `prlctl list <vm_uuid> --info --json`
    # `prlctl list --all --info --json`
    subprocess.stub(:execute).
      with("prlctl", "list", kind_of(String), "--info", "--json",
           kind_of(Hash)) do
        out = <<-eos
[
  {
    "ID": "#{uuid}",
    "Name": "#{vm_name}",
    "State": "stopped",
    "Home": "/path/to/#{vm_name}.pvm/",
    "GuestTools": {
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
    # `prlctl list <tpl_uuid> --info --json --template`
    # `prlctl list --all --info --json --template`
    subprocess.stub(:execute).
      with("prlctl", "list", kind_of(String), "--info", "--json", "--template",
           kind_of(Hash)) do
      out = <<-eos
[
  {
    "ID": "#{tpl_uuid}",
    "Name": "#{tpl_name}",
    "State": "stopped",
    "Home": "/path/to/#{tpl_name}.pvm/",
    "GuestTools": {
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
    # `prlsrvctl net info <net_name>, '--json', retryable: true)
    subprocess.stub(:execute).
      with("prlsrvctl", "net", "info", kind_of(String), "--json",
           kind_of(Hash)) do
      out = <<-eos
{
  "Network ID": "#{vnic_options[:name]}",
  "Type": "host-only",
  "Bound To": "#{hostonly_iface}",
  "Parallels adapter": {
    "IP address": "#{vnic_options[:adapter_ip]}",
    "Subnet mask": "#{vnic_options[:netmask]}"
  },
  "DHCPv4 server": {
    "Server address": "#{vnic_options[:dhcp][:ip] || "10.37.132.1"}",
    "IP scope start address": "#{vnic_options[:dhcp][:lower] || "10.37.132.1"}",
    "IP scope end address": "#{vnic_options[:dhcp][:upper] || "10.37.132.254"}"
  }
}
      eos
      subprocess_result(stdout: out)
    end

  end

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
end
