# Définition de la route par défaut
# Cette commande est à rappeler à chaque reload de Vagrant sans quoi les workers peuvent encore 
# s'initialiser sur la mauvaise carte réseau.
sudo ip route add default via 192.168.8.1