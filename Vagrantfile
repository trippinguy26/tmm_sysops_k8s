# -*- mode: ruby -*-
# vi: set ft=ruby :

# Liste des machines
machines = [
  { :hostname => "cpn", :ip => "192.168.8.200", :box => "ubuntu/jammy64", :ram => 4096, :cpu => 2, :script => "conf-cpn.sh" },
  { :hostname => "wn1", :ip => "192.168.8.201", :box => "ubuntu/jammy64", :ram => 4096, :cpu => 2, :script => "conf-nodes-all.sh" },
  { :hostname => "wn2", :ip => "192.168.8.202", :box => "ubuntu/jammy64", :ram => 4096, :cpu => 2, :script => "conf-nodes-all.sh" }
]

Vagrant.configure(2) do |config|
  machines.each do |machine|
    config.vm.define machine[:hostname] do |node|
      node.vm.box = machine[:box]
      node.vm.hostname = machine[:hostname]
      node.vm.network "public_network", ip: machine[:ip]
      node.vm.provider "virtualbox" do |vb|
        vb.gui = false
        vb.memory = machine[:ram]
        vb.cpus = machine[:cpu]
      end
      node.vm.provision "shell", path: machine[:script]
    end
  end
end
