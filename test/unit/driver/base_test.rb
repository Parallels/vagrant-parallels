require_relative '../base'

require VagrantPlugins::Parallels.source_root.join('lib/vagrant-parallels/driver/base')

describe VagrantPlugins::Parallels::Driver::Base do
  include_context 'parallels'
  before do
    stub_const('Vagrant::Util::Subprocess', subprocess)
    allow(subprocess).to receive(:execute).
        with('mdfind', any_args).
        and_return(subprocess_result(stdout: "/application.app"))

    allow(File).to receive(:exist?).with(any_args).and_return(true)
  end

  describe 'read_guest_tools_iso_path' do
    subject(:instance) { described_class.new uuid }

    it "reads `linux`:nil success" do
      expect(instance.read_guest_tools_iso_path('linux')).to end_with('prl-tools-lin.iso')
    end
    it "reads `linux`:`x86_64` success" do
      expect(instance.read_guest_tools_iso_path('linux', 'x86_64')).to end_with('prl-tools-lin.iso')
    end
    it "reads `linux`:`aarch64` success" do
      expect(instance.read_guest_tools_iso_path('linux', 'aarch64')).to end_with('prl-tools-lin-arm.iso')
    end
    it "reads `linux`:`arm64` success" do
      expect(instance.read_guest_tools_iso_path('linux', 'arm64')).to end_with('prl-tools-lin-arm.iso')
    end

    it "reads `darwin`:nil success" do
      expect(instance.read_guest_tools_iso_path('darwin')).to end_with('prl-tools-mac.iso')
    end
    it "reads `darwin`:`x86_64` success" do
      expect(instance.read_guest_tools_iso_path('darwin', 'x86_64')).to end_with('prl-tools-mac.iso')
    end
    it "reads `darwin`:`aarch64` success" do
      expect(instance.read_guest_tools_iso_path('darwin', 'aarch64')).to end_with('prl-tools-mac-arm.iso')
    end
    it "reads `darwin`:`arm64` success" do
      expect(instance.read_guest_tools_iso_path('darwin', 'arm64')).to end_with('prl-tools-mac-arm.iso')
    end
    it "reads `darwin`:`arm` success" do
      expect(instance.read_guest_tools_iso_path('darwin', 'arm')).to end_with('prl-tools-mac-arm.iso')
    end

    it "reads `windows`:nil success" do
      expect(instance.read_guest_tools_iso_path('windows')).to end_with('prl-tools-win.iso')
    end
    it "reads `windows`:`x86_64` success" do
      expect(instance.read_guest_tools_iso_path('windows', 'x86_64')).to end_with('prl-tools-win.iso')
    end
    it "reads `windows`:`aarch64` success" do
      expect(instance.read_guest_tools_iso_path('windows', 'aarch64')).to end_with('prl-tools-win-arm.iso')
    end

    it "reads `unknown`:nil success" do
      expect(instance.read_guest_tools_iso_path('unknown')).to eq(nil)
    end

    it "reads `linux`:nil exception" do
      VagrantPlugins::Parallels::Plugin.setup_i18n
      allow(File).to receive(:exist?).and_return(false)
      expect { instance.read_guest_tools_iso_path('linux') }.to raise_exception
    end
  end
end
