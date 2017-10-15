require 'vagrant'
require_relative 'base'

require VagrantPlugins::Parallels.source_root.join('lib/vagrant-parallels/config')
require VagrantPlugins::Parallels.source_root.join('lib/vagrant-parallels/synced_folder')

describe VagrantPlugins::Parallels::SyncedFolder do
  let(:machine) do
    double('machine').tap do |m|
      allow(m).to receive_messages(provider_config: VagrantPlugins::Parallels::Config.new)
      allow(m).to receive_messages(provider_name: :parallels)
    end
  end

  subject { described_class.new }

  before do
    machine.provider_config.finalize!
  end

  describe 'usable' do
    it 'should be with parallels provider' do
      allow(machine).to receive_messages(provider_name: :parallels)
      expect(subject).to be_usable(machine)
    end

    it 'should not be with another provider' do
      allow(machine).to receive_messages(provider_name: :virtualbox)
      expect(subject).not_to be_usable(machine)
    end

    it 'should not be usable if not functional psf' do
      machine.provider_config.functional_psf = false
      expect(subject).to_not be_usable(machine)
    end
  end

  describe 'prepare' do
    let(:driver) { double('driver') }

    before do
      allow(machine).to receive_messages(driver: driver)
    end

    it 'should share the folders'
  end
end
