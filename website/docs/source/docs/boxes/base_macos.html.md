---
page_title: "Creating a macOS Base Box Manually"
sidebar_current: "boxes-macos-base"
---

# Creating a macOS Base Box Manually

Prior to reading this page, please check out the [basics of the Vagrant
box file format](https://www.vagrantup.com/docs/boxes/format.html).

## Pre-requisites

* Install Vagrant, you can find the instructions [here](/docs/installation)

* Start Parallels Desktop and create a new macOS virtual machine as outlined  in [KB 125561](http://kb.parallels.com/125561/).
    <div class="alert alert-info">
    <p>
        While creating the VM, give the username as ‘vagrant’ only.<br />
        If this is a public box you should set the password to ‘vagrant’ as well.
    </p>
    </div>

  * Enable passwordless sudo for macOS virtual machine
  * Open Terminal in macOS virtual machine and run:

     ```bash
     $ sudo visudo
     ```

    Edit the line:

    ```bash
    %admin ALL=(ALL) ALL
    ```

    To Say:

    ``` bash
    %admin ALL=(ALL) NOPASSWD: ALL
    ```

    Now, you should be able to run sudo without password.

* Install Parallels Tools inside the macOS virtual machine.  
    macOs 13 > **Install Parallels Tools**
  ![install_parallels_extension](/images/install_extension.gif)

      <div class="alert alert-info">
    <p>
        <strong>Note:</strong> Installing the Parallels Tools will require a reboot
    </p>
    </div>

* Boot macOS virtual machine and enable Remote Login (System Settings > General > Sharing > Enable Remote Login). Don't forget to give “Full disk access to users”, do allow “All users” (in the same settings, press ![info](/images/info_32.png) button)
![Parallels Desktop](/images/allow_sharing.gif)
* Restart macOS virtual machine for the Remote Login to take effect.

## SSH Keys

We will need to create a new SSH keypair for Vagrant to use to communicate, we will be creating one from our host.  
You can also use the vagrant public boxes key found [here](https://github.com/hashicorp/vagrant/tree/main/keys)

* Create an ssh public-private key from the host.
  * Start Terminal on the host side.
  * Execute the following command:

        ``` bash
        $ ssh-keygen -t rsa
        ```

  * After every step press "Enter". You don't need to use a passphrase or file. As a result, you will get a similar output as in the example below:
  ![ssh_key](/images/ssh_key.jpeg)
  It will generate the files below in the ~/.ssh/ directory:
  ![ssh_pair](/images/ssh_pair.png)
* Upload the public key to macOS virtual machine from your host by executing the command below in Terminal:
  
    ``` bash
    $ ssh-copy-id vagrant@<virtual machine's ipv4 address>
    ```

    <div class="alert alert-info">
    <p>
        <strong>Note:</strong> To check your virtual machine's IP address, go to Finder > System Settings > Network > Ethernet > IP address.
    </p>
    </div>

## Create Base Box

* In Parallels directory on your Mac create a folder (something simple like ```VagrantTest```).
* Copy the initially created bundle of your macOS virtual machine (it has the **.macvm** extension) to the newly created folder (```VagrantTest```).
    
    <div class="alert alert-info">
    <p>
        <strong>Optional:</strong> You can rename macOS virtual machine with a unique name so that you won't get any name collision issues.
    </p>
    </div>

  * Run Terminal on the host side and execute the following command:
  
    ``` bash
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
* Download [Vagrantfile](https://kb.parallels.com/Attachments/kcs-191881/Vagrantfile) and put it in the VagrantTest folder.
* Download [metadata.json](https://kb.parallels.com/Attachments/kcs-191881/metadata.json) file and put it in the VagrantTest folder.
* Copy your **private** key from ~/.ssh/ directory in VagrantTest directory and rename it to '**vagrant\_private\_key**':
  ![vagrant_private_key](/images/vagrant_private_key.png)
* Create a box by Terminal.
  * Execute the following command:
    
    ``` bash
    $ cd VagrantTest
    $ tar cvzf custom.box ./box.macvm ./Vagrantfile ./metadata.json ./vagrant_private_key
    ```

    where:  

    ```custom.box``` \- any box name. For example, vagrant.box, vagrant\_project.box, etc.  
    ```box.macvm``` \- macOS virtual machine's name from step 1 (for example, ```macOS\_13.macvm```)  
    ```Vagrantfile```, ```metadata.json```, ```vagrant\_private_key``` - files from VagrantTest folder.  

    <div class="alert alert-info">
    <p>
        <strong>Note:</strong> The name of the macOS 13 virtual machine should not contain any spaces.
    </p>
    </div>

    ![custom_box](/images/custom_box.png)
* Add the created box into vagrant boxes:

    * Run Terminal and execute:

    ``` bash
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
* Download the defautl [Vagrantfile](https://kb.parallels.com/Attachments/kcs-191881/Vagrantfile) and put it in ```VFTest``` folder, or the folder you have created in the previous step.
  ![vagrantfile_folder](/images/vagrantfile_folder.png)

* In Terminal you should go to the directory with Vagrantfile ('VFTest' folder from step 15). Just type:

    ```bash
    $ cd <path to the VFTest folder>
    ```
* You can now start the vagrant box by typing:

    ```bash
    $ vagrant up -provider=parallels
    ```

    This command will start macOS virtual machine (the name of the virtual machine will be different):
    ![macos_vm_started](/images/macos_vm_started.png)

    Now you are ready to execute Vagrant commands.
