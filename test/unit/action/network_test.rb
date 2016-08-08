require_relative '../base'

require 'vagrant/util/platform'

describe VagrantPlugins::Parallels::Action::Network do
  include_context 'vagrant-unit'
  include_context 'parallels'

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile('')
    env.create_vagrant_env
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :parallels).tap do |m|
      m.provider.stub(driver: driver)
    end
  end

  let(:env)    {{ machine: machine, ui: machine.ui }}
  let(:app)    { lambda { |*args| }}
  let(:driver) { double('driver') }
  let(:guest)  { double('guest') }

  subject { described_class.new(app, env) }

  before do
    allow(driver).to receive(:enable_adapters)
    allow(driver).to receive(:read_network_interfaces) { {} }
    allow(machine).to receive(:guest) { guest }
    allow(guest).to receive(:capability)
  end

  it 'calls the next action in the chain' do
    called = false
    app = lambda { |*args| called = true }

    action = described_class.new(app, env)
    action.call(env)

    expect(called).to eq(true)
  end

  context 'with private network' do
    let(:virtualnets) { [] }
    let(:bridgedifs)  { [] }
    let(:hostonlyifs) { [] }
    let(:network_args) { {} }

    before do
      machine.config.vm.network 'private_network', network_args
      allow(driver).to receive(:read_bridged_interfaces) { bridgedifs }
      allow(driver).to receive(:read_virtual_networks) { virtualnets }
      allow(driver).to receive(:read_host_only_interfaces) { hostonlyifs }
    end

    context 'with type dhcp' do
      let(:network_args) {{ type: 'dhcp' }}

      it 'creates a host only interface and configures network in the guest' do
        allow(driver).to receive(:create_host_only_network) {{ name: 'vagrant-vnet0' }}

        subject.call(env)

        expect(driver).to have_received(:create_host_only_network).with(
          {
            network_id: 'vagrant-vnet0',
            adapter_ip: '10.37.129.1',
            netmask:    '255.255.255.0',
            dhcp:       {
              ip:    '10.37.129.1',
              lower: '10.37.129.2',
              upper: '10.37.129.254'
            }
          }
        )

        expect(guest).to have_received(:capability).with(
          :configure_networks, [{
                                  type:        :dhcp,
                                  adapter_ip:  '10.37.129.1',
                                  ip:          '10.37.129.1',
                                  netmask:     '255.255.255.0',
                                  auto_config: true,
                                  interface:   nil
                                }]
        )
      end
    end

    context 'with static ip' do
      let (:network_args) {{ ip: '172.28.128.3' }}

      context 'when the desired host-only network exists' do
        let(:hostonlyifs) {
          [{
             name:     'vagrant-vnet2',
             bound_to: 'vnic4',
             ip:       '172.28.128.2',
             netmask:  '255.255.255.0',
             status:   'Up'
           }]
        }

        it 'uses the existing host-only network' do
          allow(guest).to receive(:capability)
          allow(driver).to receive(:create_host_only_network)

          subject.call(env)

          expect(driver).not_to have_received(:create_host_only_network).with({network_id: 'vagrant-vnet2'})
        end
      end

      it 'creates a host only interface and configures network in the guest' do
        allow(driver).to receive(:create_host_only_network) {{ name: 'vagrant-vnet0' }}

        subject.call(env)

        expect(driver).to have_received(:create_host_only_network).with(
          {
            network_id: 'vagrant-vnet0',
            adapter_ip: '172.28.128.1',
            netmask:    '255.255.255.0'
          }
        )

        expect(guest).to have_received(:capability).with(
          :configure_networks, [{
                                  type:        :static,
                                  adapter_ip:  '172.28.128.1',
                                  ip:          '172.28.128.3',
                                  netmask:     '255.255.255.0',
                                  auto_config: true,
                                  interface:   nil
                                }]
        )
      end
    end
  end

  context 'with public network' do
    let(:virtualnets) { [] }
    let(:bridgedifs)  { [] }
    let(:hostonlyifs) { [] }
    let(:network_args) { {} }

    before do
      machine.config.vm.network 'public_network', network_args
      allow(driver).to receive(:read_bridged_interfaces) { bridgedifs }
    end

    context 'when bridge interface is specified and available' do
      let(:network_args) {{ type: 'dhcp', bridge: 'en0' }}
      let(:bridgedifs)  { [{ name:'en0' }] }

      it 'bridges to the host interface and configures network in the guest' do
        subject.call(env)

        expect(guest).to have_received(:capability).with(
          :configure_networks, [{
                                  type:        :dhcp,
                                  auto_config: true,
                                  interface:   nil,
                                  use_dhcp_assigned_default_route: false
                                }]
        )
      end
    end

    context 'when bridge interface should be chosen' do
      let(:network_args) {{ type: 'dhcp' }}
      let(:bridgedifs)  { [{ name:'en0' }, { name: 'en1' }] }

      it 'bridges to the host interface and configures network in the guest' do
        allow(env[:ui]).to receive(:ask).and_return('2')

        subject.call(env)
        expect(guest).to have_received(:capability).with(
          :configure_networks, [{
                                  type:        :dhcp,
                                  auto_config: true,
                                  interface:   nil,
                                  use_dhcp_assigned_default_route: false
                                }]
        )
      end
    end

  end

end