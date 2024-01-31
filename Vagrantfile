# -*- mode: ruby -*-
# vi: set ft=ruby :

# Liste des machines
machines = [
  { :hostname => "cpn", :ip => "192.168.8.200", :box => "ubuntu/jammy64", :ram => 4096, :cpu => 2, :script1 => "conf-cpn.sh", :script2 => "force-route.sh" },
  { :hostname => "wn1", :ip => "192.168.8.201", :box => "ubuntu/jammy64", :ram => 4096, :cpu => 2, :script1 => "conf-wn.sh", :script2 => "force-route.sh" },
  { :hostname => "wn2", :ip => "192.168.8.202", :box => "ubuntu/jammy64", :ram => 4096, :cpu => 2, :script1 => "conf-wn.sh", :script2 => "force-route.sh" }
]

# Config des machines
Vagrant.configure(2) do |config|
  machines.each do |machine|
    config.vm.define machine[:hostname] do |node|
      node.vm.box = machine[:box]
      node.vm.hostname = machine[:hostname]
      node.vm.network "public_network", ip: machine[:ip], netmask: machine[:netmask]
      node.vm.provider "virtualbox" do |vb|
        vb.gui = false
        vb.memory = machine[:ram]
        vb.cpus = machine[:cpu]
      end
      node.vm.provision "shell", path: machine[:script1], run: "once"
      node.vm.provision "shell", path: machine[:script2], run: "always"
    end
  end
end
