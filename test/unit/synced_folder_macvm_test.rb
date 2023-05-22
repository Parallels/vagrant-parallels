require 'vagrant'
require_relative 'base'

require VagrantPlugins::Parallels.source_root.join('lib/vagrant-parallels/config')
require VagrantPlugins::Parallels.source_root.join('lib/vagrant-parallels/synced_folder_macvm')

describe VagrantPlugins::Parallels::SyncedFolderMacVM do
  let(:machine) do
    double('machine').tap do |m|
      allow(m).to receive_messages(provider_name: :parallels)
      allow(VagrantPlugins::Parallels::Util::Common).to receive(:is_macvm).with(m).and_return(true)
    end
  end

  subject { described_class.new }

  describe 'usable' do
    it 'should be with parallels provider' do
      allow(machine).to receive_messages(provider_name: :parallels)
      expect(subject).to be_usable(machine)
    end

    it 'should not be with another provider' do
      allow(machine).to receive_messages(provider_name: :virtualbox)
      expect(subject).not_to be_usable(machine)
    end

    it 'should be with macvm guest' do
      allow(VagrantPlugins::Parallels::Util::Common).to receive(:is_macvm).with(machine).and_return(true)
      expect(subject).to be_usable(machine)
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
