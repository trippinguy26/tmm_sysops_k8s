# Script install Kubernetes selon la méthode TeachMeMore + GPT (22/01/2024)

# Installation du moteur de conteneurisation (ne plus utiliser docker)
# Ajouter la clé GPG officielle de Docker :
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Ajouter le dépôt aux sources d'Apt :
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
#sudo apt-get install -y containerd.io

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