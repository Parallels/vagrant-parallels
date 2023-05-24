---
page_title: "Creating a macOS Base Box Manually"
sidebar_current: "boxes-macos-base"
---

# Creating a macOS Base Box Manually

Prior to reading this page, please check out the [basics of the Vagrant
box file format](https://www.vagrantup.com/docs/boxes/format.html).

## Pre-requisites

* Install Vagrant, you can find the instructions [here](/vagrant-parallels/docs/installation)

* Start Parallels Desktop and create a new macOS virtual machine as outlined  in [KB 125561](http://kb.parallels.com/125561/).
    <div class="alert alert-info">
    <p>
        While creating the VM, give the username as ‘vagrant’ only.<br />
        If this is a public box you should set the password to ‘vagrant’ as well.
    </p>
    </div>

  * Enable passwordless sudo for `vagrant` user on macOS virtual machine:
    * Open Terminal in macOS virtual machine and run:

       ```bash
       $ sudo visudo /private/etc/sudoers.d/vagrant
       ```

      Paste this line there and save the file (`:wq`) :

      ```bash
      vagrant ALL = (ALL) NOPASSWD: ALL
      ```

      Now `vagrant` user is allowed to run `sudo` without a password prompt.

* Install Parallels Tools inside the macOS virtual machine.  
    macOs 13 > **Install Parallels Tools**
  ![install_parallels_tools](/images/install_parallels_tools.gif)

      <div class="alert alert-info">
    <p>
        <strong>Note:</strong> Installing the Parallels Tools will require a reboot
    </p>
    </div>

* Reboot macOS virtual machine and then enable Remote Login (_System Settings > General > Sharing > Enable Remote Login_). Select “All users” and also enable “Full disk access to users”, as shown on the picture below:  
![allow_remote_login](/images/allow_remote_login.gif)
* Copy the vagrant public SSH key to the machine
  
    ```bash
    $ ssh-copy-id -i $(find /opt/vagrant/embedded/gems -type d -name keys)/vagrant vagrant@<virtual_machine_ip>
    ```

    where `<virtual_machine_ip>` is the current IP of the virtual machine, which could be determined using this command:

    ```bash
    $ prlctl list -f 
    ``` 

## Create Base Box

* In Parallels directory on your Mac create a folder (something simple like ```VagrantTest```).
* Copy the initially created bundle of your macOS virtual machine (it has the **.macvm** extension) to the newly created folder (```VagrantTest```).
    
    <div class="alert alert-info">
    <p>
        <strong>Optional:</strong> You can rename macOS virtual machine with a unique name so that you won't get any name collision issues.
    </p>
    </div>

  * Run Terminal on the host side and execute the following command:
  
    ```bash
    $ prlctl set "macOS 13" --name "macOS_13"
    ```

    Where the name 'macOS_13' is your virtual machine's name.

    <div class="alert alert-info">
    <p>
        <strong>Note:</strong> Renaming the virtual machine is one of the solutions to avoid name collision. You can also remove macOS virtual machine from Control Center (Parallels icon > Control Center > Right-click on macOS 13 virtual machine > Remove 'macOS 13' > <strong>Keep Files</strong>).
    </p>
    </div>

    <div class="alert alert-warn">
    <p>
        <strong>Attention:</strong> If you used the public vagrant ssh key then you will not need to do the next steps as they are only copying the ssh key that you generated.
    </p>
    </div>
* Download [metadata.json](https://kb.parallels.com/Attachments/kcs-191881/metadata.json) file and put it in the VagrantTest folder.
* Create a box by Terminal.
  * Execute the following command:

    ```bash
    $ cd VagrantTest
    $ tar cvzf custom.box ./box.macvm ./metadata.json
    ```

    where:  

    ```custom.box``` \- any box name. For example, vagrant.box, vagrant\_project.box, etc.  
    ```box.macvm``` \- macOS virtual machine's name from step 1 (for example, ```macOS\_13.macvm```)  
    ```metadata.json``` - files from VagrantTest folder.  

    <div class="alert alert-info">
    <p>
        <strong>Note:</strong> The name of the macOS 13 virtual machine should not contain any spaces.
    </p>
    </div>

    ![custom_box](/images/custom_box.png)
* Add the created box into vagrant boxes:

    * Run Terminal and execute:

    ```bash
    $ vagrant box add <name>.box --name macOS13
    ```

    where ```<name>```.box is the name of the box created in the previous step.

* Go to **~/.vagrant.d/boxes/macOS13** folder and check that extension of macOS virtual machine is ```.macvm```:
  ![check_extension_macvm](/images/check_extension_macvm.png)

## Create a Vagrant folder

We now have our base box created, to create virtual machines from it we will need to create a Vagrant folder structure and a Vagrantfile.

* Create a new folder in the home directory and name it VFTest (In the Finder, you can open your home folder by choosing **Go** > **Home** or by pressing **Shift-Command-H**).

    <div class="alert alert-info">
    <p>
        <strong>Note:</strong> The name of the folder can be different. 'VFTest' is just for example.
    </p>
    </div>
* You can now start the vagrant box by typing:

    ```bash
    $ cd <path to the folder>
    $ vagrant init macOS13
    $ vagrant up -provider=parallels
    ```

    This command will start macOS virtual machine (the name of the virtual machine will be different):
    ![macos_vm_started](/images/macos_vm_started.png)

    Now you are ready to execute Vagrant commands.