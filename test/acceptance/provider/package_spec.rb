# This tests that packaging works with a given provider.
shared_examples 'provider/package' do |provider, options|
  if !options[:box]
    raise ArgumentError,
          "box option must be specified for provider: #{provider}"
  end

  include_context 'acceptance'

  it "can't package before an up" do
    expect(execute('vagrant', 'package')).to exit_with(1)
  end

  context 'with a running machine' do
    before do
      # Create VM as a linked clone to test that it could be packaged correctly
      environment.skeleton('linked_clone')

      assert_execute('vagrant', 'box', 'add', 'basic', options[:box])
      assert_execute('vagrant', 'up', "--provider=#{provider}")
    end

    after do
      # Just always do this just in case
      execute('vagrant', 'destroy', '--force', log: false)
    end

    it 'can package and bring the box back up' do
      status('Test: linked clone could be packaged to the standalone box')
      expect(execute('vagrant', 'package')).to exit_with(0)
      assert_execute('vagrant', 'destroy', '--force')

      path = environment.workdir.join('package.box')
      expect(path).to be_file

      begin
        # Create a new environment and bring up the packaged box
        status('Test: packaged box could be reused')
        new_env = new_environment
        assert_execute('vagrant', 'box', 'add', 'temp', path.to_s, env: new_env)
        assert_execute('vagrant', 'init', 'temp', env: new_env)
        assert_execute('vagrant', 'up', "--provider=#{provider}", env: new_env)

        # Test again for Vagrant issue GH-5780
        status('Test: box could be re-package (issue mitchellh/vagrant#5780)')
        assert_execute('vagrant', 'package', env: new_env)
        assert_execute('vagrant', 'destroy', '--force', env: new_env)

        path = new_env.workdir.join('package.box')
        new_env2 = new_environment
        assert_execute('vagrant', 'box', 'add', 'temp', path.to_s, env: new_env2)
        assert_execute('vagrant', 'init', 'temp', env: new_env2)
        assert_execute('vagrant', 'up', "--provider=#{provider}", env: new_env)
        assert_execute('vagrant', 'destroy', '--force', env: new_env2)
      ensure
        if new_env
          new_env.execute('vagrant', 'destroy', '--force')
          new_env.close
        end

        if new_env2
          new_env2.execute('vagrant', 'destroy', '--force')
          new_env2.close
        end
      end
    end
  end
end
