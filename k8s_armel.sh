#!/bin/bash

# Configuration initiale
# 1. 4 machines virtuelles Ubuntu 22.04, 1 contrôleur, 3 nœuds.
# 2. Adresses IP statiques sur chaque machine virtuelle
# 3. Le fichier /etc/hosts inclut des correspondances nom-IP pour les machines virtuelles
# 4. La mémoire virtuelle (swap) est désactivée
# 5. Prenez des instantanés avant l'installation

# Désactiver la mémoire virtuelle (swap)
sudo swapoff -a
# Modifier le fichier /etc/fstab pour supprimer les entrées de swap
# Cette partie nécessite une intervention manuelle avec vi ou un autre éditeur
# vi /etc/fstab

# Installer les packages prérequis pour containerd
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Appliquer les paramètres sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# Installer containerd depuis le dépôt Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y containerd.io

# Créer un fichier de configuration containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Modifier le fichier de configuration containerd pour utiliser le pilote cgroup systemd
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml

# Redémarrer containerd
sudo systemctl restart containerd

# Installer kubeadm, kubelet et kubectl
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
# Installer une version spécifique de Kubernetes
VERSION=1.26.0-00
sudo apt-get install -y kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION
sudo apt-mark hold kubelet kubeadm kubectl containerd

# Vérifier l'état de kubelet et containerd
sudo systemctl status kubelet.service
sudo systemctl status containerd.service

# Activer kubelet et containerd pour démarrer au démarrage du système
sudo systemctl enable kubelet.service
sudo systemctl enable containerd.service
