VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.box = "precise64"
    config.vm.box_url = "http://files.vagrantup.com/precise64.box"

    config.vm.define :master do |sphinx|
        sphinx.vm.hostname = "sphinx"
        sphinx.vm.network :private_network, ip: "192.168.100.100"

        sphinx.vm.synced_folder "salt/roots", "/srv/salt"
        
        sphinx.vm.provision :salt do |salt|
            salt.minion_config = "salt/config/sphinx"
            salt.run_highstate = true
        end
    end
    
    config.vm.provider "virtualbox" do |v|
        v.memory = 1024
        v.cpus = 1
    end
end