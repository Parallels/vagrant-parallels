shared_examples 'provider/snapshot' do |provider, options|
  if !options[:box]
    raise ArgumentError,
      "box option must be specified for provider: #{provider}"
  end

  include_context 'acceptance'

  before do
    assert_execute('vagrant', 'box', 'add', 'box', options[:box])
    assert_execute('vagrant', 'init', 'box')
    assert_execute('vagrant', 'up', "--provider=#{provider}")
  end

  after do
    assert_execute('vagrant', 'destroy', '--force')
  end

  it 'can save, list and delete machine snapshots' do
    status('Test: two snapshots could be created')
    assert_execute('vagrant', 'snapshot', 'save', 'foo')
    assert_execute('vagrant', 'snapshot', 'save', 'bar')

    status('Test: snapshots show up in list')
    result = execute('vagrant', 'snapshot', 'list')
    expect(result).to exit_with(0)
    expect(result.stdout).to match(/^foo$/)
    expect(result.stdout).to match(/^bar$/)

    status('Test: snapshots could be restored')
    assert_execute('vagrant', 'snapshot', 'restore', 'foo')
    assert_execute('vagrant', 'snapshot', 'restore', 'bar')

    status('Test: snapshots could be deleted')
    assert_execute('vagrant', 'snapshot', 'delete', 'foo')
    assert_execute('vagrant', 'snapshot', 'delete', 'bar')

    result = execute('vagrant', 'snapshot', 'list')
    expect(result).to exit_with(0)
    expect(result.stdout).not_to match(/^foo$/)
    expect(result.stdout).not_to match(/^bar$/)
  end

  it 'can push and pop snapshots' do
    status('Test: snapshot push')
    result = execute('vagrant', 'snapshot', 'push')
    expect(result).to exit_with(0)
    expect(result.stdout).to match(/push_/)

    status('Test: pushed snapshot shows up in list')
    result = execute('vagrant', 'snapshot', 'list')
    expect(result).to exit_with(0)
    expect(result.stdout).to match(/^push_/)

    status('Test: snapshot pop')
    assert_execute('vagrant', 'snapshot', 'pop')

    status('Test: popped snapshot has been deleted')
    result = execute('vagrant', 'snapshot', 'list')
    expect(result).to exit_with(0)
    expect(result.stdout).not_to match(/push_/)
  end
end
