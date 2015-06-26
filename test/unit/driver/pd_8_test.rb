require_relative "../base"

describe VagrantPlugins::Parallels::Driver::PD_8 do
  include_context "parallels"
  let(:parallels_version) { "8" }

  subject { VagrantPlugins::Parallels::Driver::Meta.new(uuid) }

  it_behaves_like "parallels desktop driver"
end
