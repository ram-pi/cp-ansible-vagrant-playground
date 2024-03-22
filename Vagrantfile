Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.hostname = "confluent"
  config.vm.box_check_update = false
  config.vm.disk :disk, primary: true, size: "100GB"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 9092, host: 9092, host_ip: "127.0.0.1"
  # config.vm.network "forwarded_port", guest: 9021, host: 9021, host_ip: "127.0.0.1"
  # config.vm.network "forwarded_port", guest: 8090, host: 8090, host_ip: "127.0.0.1"
  # config.vm.network "forwarded_port", guest: 389, host: 389, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.33.10"

  config.vagrant.plugins = "vagrant-docker-compose"

  # install docker and docker-compose
  config.vm.provision :docker
  config.vm.provision :docker_compose

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--memory", "4096"]
    vb.customize ["modifyvm", :id, "--cpus", "2"]
  end

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update -y
    apt-get install -y docker 
    apt-get install -y git
    apt-get install -y net-tools
    apt-get install -y ldap-utils
    apt-get install -y jq
    git clone https://github.com/ram-pi/docker-ldap.git
    cd docker-ldap
    docker-compose up -d
  SHELL
end
