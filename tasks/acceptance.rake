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
      synced_folder_parallels
      synced_folder/rsync
      provisioner/shell
      provisioner/chef-solo
      package
    ).map{ |s| "provider/parallels/#{s}" }
#   synced_folder/nfs is removed as vagrant nfs is not working in latest macOS versions.
#   TODO: check how to support nfs for latest macOSes
    command = "vagrant-spec test --components=#{components.join(' ')}"
    puts command
    puts
    exec(command)
  end
end
