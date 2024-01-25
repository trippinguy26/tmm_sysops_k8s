# Configuration 
#   1. 3 VMs Ubuntu 22.04, 1 plan de contrôle, 2 nœuds.
#   2. IPs statiques sur les VM individuelles
#   3. Le fichier /etc/hosts comprend les mappages de noms vers IPs pour les VMs
#   4. La swap est désactivée
#   5. Prenez des instantanés avant l'installation, ainsi vous pouvez installer 
#       et revenir à l'instantané si nécessaire 
#
#ssh ip_controlplanenode

# 0 - Désactivez la swap, utilisez swapoff puis modifiez votre fstab en supprimant toute entrée pour les partitions swap
# Vous pouvez récupérer l'espace avec fdisk. Vous voudrez peut-être redémarrer pour vous assurer que votre configuration est correcte.
sudo swapoff -a

# Définition de la route par défaut
sudo ip route add default via 192.168.8.1

# 0 - Installer les paquets
# Prérequis de containerd, chargez deux modules et configurez-les pour qu'ils se chargent au démarrage
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

#Activation de l'IPv4 forwarding
echo "1" | sudo tee /proc/sys/net/ipv4/ip_forward
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Paramètres sysctl nécessaires à la configuration, les paramètres persistent après les redémarrages
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Appliquer les paramètres sysctl sans redémarrage
sudo sysctl --system

# Installer containerd... il faut installer depuis le dépôt docker pour obtenir containerd 1.6, le dépôt ubuntu s'arrête à 1.5.9
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update 
sudo apt-get install -y containerd.io

# Créez un fichier de configuration containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Définissez le pilote cgroup pour containerd sur systemd, nécessaire pour le kubelet.
# Pour plus d'informations sur ce fichier de configuration, voir :
# https://github.com/containerd/cri/blob/master/docs/config.md et aussi
# https://github.com/containerd/containerd/blob/master/docs/ops.md

# À la fin de cette section, changez SystemdCgroup = false en SystemdCgroup = true
#        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
#        ...
#          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
#            SystemdCgroup = true

# Vous pouvez utiliser sed pour remplacer par true
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml

# Vérifiez que le changement a été effectué
#sudo vi /etc/containerd/config.toml

# Redémarrez containerd avec la nouvelle configuration
sudo systemctl restart containerd

# Installez les paquets Kubernetes - kubeadm, kubelet et kubectl
# Ajoutez la clé gpg du dépôt apt de Google (en erreur)
#sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

# Ajoutez le dépôt apt de Kubernetes (en erreur)
#echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Mettez à jour la liste des paquets et utilisez apt-cache policy pour inspecter les versions disponibles dans le dépôt
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -4 -sL https://dl.k8s.io/apt/doc/apt-key.gpg | sudo apt-key add -
sudo touch /etc/apt/sources.list.d/kubernetes.list
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
apt-cache policy kubelet | head -n 20

# Installez les paquets requis, si nécessaire nous pouvons demander une version spécifique.
# Utilisez cette version car dans un cours ultérieur, nous mettrons à niveau le cluster vers une version plus récente.
# Essayez de choisir une version précédente car plus tard dans cette série, nous effectuerons une mise à niveau
VERSION=1.26.0-00

#sudo apt-get install -y kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION 
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl containerd

# Pour installer la dernière version, omettez les paramètres de version. J'ai testé toutes les démonstrations avec la version ci-dessus, si vous utilisez la dernière, cela peut affecter d'autres démonstrations dans ce cours et les cours à venir dans la série
# sudo apt-get install kubelet kubeadm kubectl
# sudo apt-mark hold kubelet kubeadm kubectl containerd

# 1 - Unités systemd
# Vérifiez le statut de notre kubelet et de notre runtime de conteneur, containerd.
# Le kubelet entrera dans une boucle de crash jusqu'à ce qu'un cluster soit créé ou que le nœud soit joint à un cluster existant.
#sudo systemctl status kubelet.service 
#sudo systemctl status containerd.service 

# Assurez-vous que les deux sont configurés pour démarrer lorsque le système démarre.
sudo systemctl enable kubelet.service
sudo systemctl enable containerd.service

# -------------------------------------------------------------------- #
# --------------------- Création du cluster K8S ---------------------- #
# -------------------------------------------------------------------- #

###IMPORTANT###
#Si vous utilisez containerd, assurez-vous que Docker n'est pas installé.
#kubeadm init essaiera de détecter automatiquement le runtime de conteneur et pour le moment
#s'ils sont tous les deux installés, il choisira Docker en premier.

#ssh ip_noeudControlPlane


#0 - Création d'un Cluster
#Créez notre cluster kubernetes, spécifiez une plage d'adresses réseau pour les pods qui correspond à celle dans calico.yaml!
#Seulement sur le Noeud de Plan de Contrôle, téléchargez les fichiers yaml pour le réseau de pods.
wget https://raw.githubusercontent.com/projectcalico/calico/master/manifests/calico.yaml


#Regardez à l'intérieur de calico.yaml et trouvez le paramètre pour la plage d'adresses IP du réseau Pod CALICO_IPV4POOL_CIDR,
#ajustez si nécessaire pour votre infrastructure pour vous assurer que la plage d'adresses IP du réseau de pods
#ne se chevauche pas avec d'autres réseaux dans notre infrastructure.
#vi calico.yaml
sudo sed -i 's/            # - name: CALICO_IPV4POOL_CIDR/            - name: CALICO_IPV4POOL_CIDR /' calico.yaml
sudo sed -i 's@            #   value: "192.168.0.0/16"@              value: "172.16.0.0/16" @g' calico.yaml


#Vous pouvez maintenant simplement utiliser kubeadm init pour initialiser le cluster
#sudo kubeadm init --kubernetes-version v1.26.0
sudo kubeadm init --apiserver-advertise-address=192.168.8.200

#sudo kubeadm init #supprimez le paramètre kubernetes-version si vous voulez utiliser la dernière version.


#Avant de continuer, examinez le résultat du processus de création du cluster, y compris les phases de kubeadm init,
#la configuration admin.conf et la commande de jointure des nœuds


#1 - Création d'un réseau de Pods
#Déployez le fichier yaml pour votre réseau de pods.
#Configurez notre compte sur le Noeud de Plan de Contrôle pour avoir un accès administrateur au serveur API depuis un compte non privilégié.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f calico.yaml


#Recherchez tous les pods système et les pods calico pour qu'ils passent à l'état Running.
#Le pod DNS ne démarrera pas (en attente) tant que le réseau de pods n'est pas déployé et en cours d'exécution.
#kubectl get pods --all-namespaces


#Vous donne une sortie dans le temps, plutôt que de repeindre l'écran à chaque itération.
#kubectl get pods --all-namespaces --watch


#Tous les pods système doivent être en cours d'exécution
#kubectl get pods --all-namespaces


#Obtenez une liste de nos nœuds actuels, juste le Noeud de Plan de Contrôle... il devrait être prêt.
#kubectl get nodes 


#2 - Unités systemd... encore!
#Vérifiez l'unité systemd... elle ne redémarre plus en boucle car elle a des pods statiques à démarrer
#N'oubliez pas que le kubelet démarre les pods statiques, et donc les pods du plan de contrôle
#sudo systemctl status kubelet.service 


#3 - Manifestes de Pods statiques
#Examinons les manifestes de pods statiques sur le Noeud de Plan de Contrôle
#ls /etc/kubernetes/manifests


#Et regardons de plus près le manifeste de l'API serveur et d'etcd.
#sudo more /etc/kubernetes/manifests/etcd.yaml
#sudo more /etc/kubernetes/manifests/kube-apiserver.yaml


#Vérifiez le répertoire où se trouvent les fichiers de configuration kube pour chacun des pods du plan de contrôle.
#ls /etc/kubernetes

# ---------------------------------------------------------------------------- #
# --------------------- Joindre un noeud au cluster K8S ---------------------- #
# ---------------------------------------------------------------------------- #

# Commandes pour récupérer le token
#kubeadm token list
# Commandes pour récupérer le caCertHashes
#cd /etc/kubernetes/pki
#openssl x509 -pubkey -in ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
# Ces informations seront à transmettre aux worker nodes afin qu'ils rejoingnent le cluster
# Commandes pour récupérer le token + le caCertHashes
sudo kubeadm token create --print-join-command
