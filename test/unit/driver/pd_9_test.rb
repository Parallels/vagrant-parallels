require_relative "../base"

describe VagrantPlugins::Parallels::Driver::PD_9 do
  include_context "parallels"
  let(:parallels_version) { "9" }

  let(:vm_name) {'VM_Name'}
  let(:vm_net0_mac) {'001C42B4B074'}
  let(:vm_net1_mac) {'001C42EC0068'}
  let(:vm_hdd) {'/path/to/disk1.hdd'}

  let(:tpl_uuid) {'1234-some-template-uuid-5678'}
  let(:tpl_name) {'Some_Template_Name'}
  let(:tpl_net0_mac) {'001C42F6E500'}
  let(:tpl_net1_mac) {'001C42AB0071'}

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
    # `prlctl list SOME-VM-UUID --info --json`
    # `prlctl list --all --info --json`
    subprocess.stub(:execute).
      with("prlctl", "list", kind_of(String), "--info", "--json", kind_of(Hash))do
        out = <<-eos
        [
          {
            "ID": "#{uuid}",
            "Name": "#{vm_name}",
            "State": "stopped",
            "Home": "/path/to/#{vm_name}.pvm/",
            "GuestTools": {
              "version": "9.0.23062"
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
                "image": "#{vm_hdd}"
              },
              "net0": {
                "enabled": true,
                "type": "shared",
                "mac": "#{vm_net0_mac}",
                "card": "e1000",
                "dhcp": "yes"
              },
              "net1": {
                "enabled": true,
                "type": "bridged",
                "iface": "vnic2",
                "mac": "#{vm_net1_mac}",
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
    # `prlctl list some_vm_uuid --info --json --template`
    # `prlctl list --all --info --json --template`
    subprocess.stub(:execute).
      with("prlctl", "list", kind_of(String), "--info", "--json", "--template", kind_of(Hash))do
      out = <<-eos
        [
          {
            "ID": "#{tpl_uuid}",
            "Name": "#{tpl_name}",
            "State": "stopped",
            "Home": "/path/to/#{tpl_name}.pvm/",
            "GuestTools": {
              "version": "9.0.24172"
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
                "mac": "#{tpl_net0_mac}",
                "card": "e1000",
                "dhcp": "yes"
              },
              "net1": {
                "enabled": true,
                "type": "bridged",
                "iface": "vnic4",
                "mac": "#{tpl_net1_mac}",
                "card": "e1000",
                "ips": "33.33.33.10/255.255.255.0 "
              }
            }
          }
        ]
      eos
      subprocess_result(stdout: out)
    end
  end
end
