# Script install Kubernetes selon la méthode TeachMeMore + GPT (22/01/2024)

# Installation du moteur de conteneurisation (ne plus utiliser docker)
sudo apt-get install -y containerd

# Installation de kubeadm, kubelet et kubectl
# Ces commandes installent les outils nécessaires pour ajouter un nouveau dépôt de paquets.

# Ajout de la clé du dépôt de paquets de Kubernetes à la liste des clés de confiance.
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Ajout du dépôt de paquets de Kubernetes à la liste des sources de paquets.
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Installation des prérequis
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# Marquer les paquets suivants pour ne pas les mettre à jour avec apt (cas d'utilisation de repos locaux)
sudo apt-mark hold kubelet kubeadm kubectl containerd

# ---------------------------FIN INSTALLATION--------------------------- #

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo systcl --system

# Initialisation du cluster avec Containerd
sudo kubeadm init --pod-network-cidr=10.0.8.0/24 --cri-socket /run/containerd/containerd.sock

# Configuration de kubectl pour l'utilisateur vagrant
sudo --user=vagrant mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config

# Installation du réseau de pods (Calico dans cet exemple)
sudo --user=vagrant kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml