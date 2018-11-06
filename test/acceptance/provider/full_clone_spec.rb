# This tests that VM is up as a full clone
shared_examples 'provider/full_clone' do |provider, options|
  if !options[:box]
    raise ArgumentError,
      "box option must be specified for provider: #{provider}"
  end

  include_context 'acceptance'

  before do
    environment.skeleton('full_clone')
    assert_execute('vagrant', 'box', 'add', 'basic', options[:box])
  end

  after do
    assert_execute('vagrant', 'destroy', '--force')
  end

  it 'creates machine as full clone' do
    status('Test: machine is created as a full clone')
    result = execute('vagrant', 'up', "--provider=#{provider}")
    expect(result).to exit_with(0)
    expect(result.stdout).to match(/full clone/)

    status('Test: machine is available by ssh')
    result = execute('vagrant', 'ssh', '-c', 'echo foo')
    expect(result).to exit_with(0)
    expect(result.stdout).to match(/foo\n$/)
  end
end
