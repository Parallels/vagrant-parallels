require_relative 'base'

require 'vagrant-parallels/cap'

describe VagrantPlugins::Parallels::Cap do
  include_context 'vagrant-unit'

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile('')
    env.create_vagrant_env
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :dummy).tap do |m|
      allow(m.provider).to receive_messages(driver: driver)
      allow(m).to receive_messages(state: state)
    end
  end

  let(:driver) { double('driver') }
  let(:state)  { double('state', id: :running) }

  describe '#forwarded_ports' do
    it 'returns all the forwarded ports' do
      allow(driver).to receive(:read_forwarded_ports).and_return([
        { hostport:  123, guestport: 456 },
        { hostport:  245, guestport: 245 }
      ])

      expect(described_class.forwarded_ports(machine)).to eq({
        123 => 456,
        245 => 245,
      })
    end

    it 'returns nil when the machine is not running' do
      allow(state).to receive(:id).and_return(:stopped)
      expect(described_class.forwarded_ports(machine)).to be(nil)
    end
  end

  describe '#host_address' do
    it "returns host's IP of Shared interface" do
      allow(driver).to receive(:read_shared_interface).and_return(ip: '1.2.3.4')
      expect(described_class.host_address(machine)).to eq('1.2.3.4')
    end
  end

  describe '#nic_mac_addresses' do
    it 'returns a hash with MAC addresses' do
      allow(driver).to receive(:read_mac_addresses).and_return(
        ['001A2B3C4D5E', '005E4D3C2B1A'])
      expect(described_class.nic_mac_addresses(machine)).to eq({
        1 => '001A2B3C4D5E',
        2 => '005E4D3C2B1A'
      })
    end

    it 'returns an empty hash when there are no NICs' do
      allow(driver).to receive(:read_mac_addresses).and_return([])
      expect(described_class.nic_mac_addresses(machine)).to eq({})
    end
  end

  describe '#public_address' do
    it "returns VM's IP" do
      allow(machine).to receive(:ssh_info).and_return(host: '1.2.3.4')
      expect(described_class.public_address(machine)).to eq('1.2.3.4')
    end

    it "returns nil when the machine is not running" do
      allow(state).to receive(:id).and_return(:stopped)
      expect(described_class.public_address(machine)).to be(nil)
    end

    it "returns nil when there is no ssh info" do
      allow(machine).to receive(:ssh_info).and_return(nil)
      expect(described_class.public_address(machine)).to be(nil)
    end
  end

  describe '#snapshot_list' do
    it 'returns a list of snapshots' do
      allow(machine).to receive(:id).and_return('foo')
      allow(driver).to receive(:list_snapshots).with('foo').and_return({
        'snap_name_1' => 'snap_uuid_1',
        'snap_name_2' => 'snap_uuid_2'
      })

      expect(described_class.snapshot_list(machine)).to eq(
        ['snap_name_1', 'snap_name_2'])
    end
  end
end