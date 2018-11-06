namespace :acceptance do
  desc 'shows components that can be tested separately'
  task :components do
    exec('vagrant-spec components')
  end

  desc 'runs acceptance tests using vagrant-spec'
  task :run do
    components = %w(
      basic
      full_clone
      network/forwarded_port
      network/private_network
      snapshot
      synced_folder
      synced_folder/nfs
      synced_folder/rsync
      provisioner/shell
      provisioner/chef-solo
      package
    ).map{ |s| "provider/parallels/#{s}" }

    command = "vagrant-spec test --components=#{components.join(' ')}"
    puts command
    puts
    exec(command)
  end
end
