## Init
vagrant init ubuntu/trusty64
# generates a Vagrantfile (base image)

## Management
vagrant up
# starts the VM
vagrant ssh #password: vagrant
# connects to the VM
vagrant halt
# stops the VM
vagrant destroy
# deletes the VM

## Configuration
vagrant box list # like docker images to pull from
# lists all the boxes
vagrant global-status # for environments with multiple Vagrantfiles
# lists all the VMs
vagrant box remove ubuntu/trusty64
# removes the box
vagrant box add ubuntu/trusty64
# adds the box
vagrant box update
# updates the box

## Plugin management
vagrant plugin install vagrant-vbguest
# installs the plugin
vagrant plugin list
# lists all the plugins
vagrant plugin uninstall vagrant-vbguest
# uninstalls the plugin
vagrant plugin update vagrant-vbguest
# updates the plugin