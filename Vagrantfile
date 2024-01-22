# -*- mode: ruby -*-
# vi: set ft=ruby :

# Liste des machines
machines = [
  { :hostname => "controlplane", :ip => "192.168.8.100", :box => "hashicorp/bionic64", :ram => 4096, :cpu => 2 },
  { :hostname => "nodeworker1", :ip => "192.168.8.101", :box => "hashicorp/bionic64", :ram => 4096, :cpu => 2 },
  { :hostname => "nodeworker2", :ip => "192.168.8.102", :box => "hashicorp/bionic64", :ram => 4096, :cpu => 2 }
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
      node.vm.provision "shell", path: "install_k8s.sh"
    end
  end
end
