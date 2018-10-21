require_relative '../base'

describe VagrantPlugins::Parallels::Driver::PD_11 do
  include_context 'parallels'
  let(:parallels_version) { '11' }

  subject { VagrantPlugins::Parallels::Driver::Meta.new(uuid) }

  it_behaves_like 'parallels desktop driver'

  describe 'set_power_consumption_mode' do
    it "turns 'longer-battery-life' on" do
      expect(subprocess).to receive(:execute).
        with('prlctl', 'set', uuid, '--longer-battery-life', 'on',
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      subject.set_power_consumption_mode(true)
    end

    it "turns 'longer-battery-life' off" do
      expect(subprocess).to receive(:execute).
        with('prlctl', 'set', uuid, '--longer-battery-life', 'off',
             an_instance_of(Hash)).
        and_return(subprocess_result(exit_code: 0))

      subject.set_power_consumption_mode(false)
    end
  end

end
