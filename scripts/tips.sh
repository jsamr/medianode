#!/bin/bash
# monter un répertoire samba
sudo mount -t cifs -o username='\Administrateur',password='!domuslab1',gid='media-node' //10.44.163.150/Son ./Cuisine

# publier un répertoire nfs
# SERVEUR
# ------------------------
# 1. installer nfs
# sudo apt-get install nfs-kernel-server nfs-common

# 2. editer /etc/exports en ajoutant
# /prj_dei dinf-merle.dinf.fsci.usherbrooke.ca(rw,no_subtree_check,async)

# 3. relancer le serveur nfs
# sudo /etc/init.d/nfs-kernel-server restart

# 4. mettre a jour les changements
# sudo exportfs -a

# 5. Vérifier que l'export fonctionne
# showmount -e

# 6. Si le serveur utilise ufw, ouvrir les ports adéquats pour l'ip du client $IP_CLIENT
# sudo ufw allow from $IP_CLIENT to any port 111
# sudo ufw allow from $IP_CLIENT to any port 2049
# sudo ufw reload
# CLIENT
# ------------------------

# 1. installer nfs commons
# sudo apt-get install nfs-common
# 2. tester avec mount
# sudo mount -t nfs dinf-merle.dinf.fsci.usherbrooke.ca:/data/dei_prj /media/node/DEI
# 3. ajouter à /etc/fstab
# dinf-mignard.dinf.fsci.usherbrooke.ca:/data/dei_prj  /media/colab  nfs  rsize=8192 and wsize=8192,noexec,nosuid,gid=media-node