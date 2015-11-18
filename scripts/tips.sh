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

# CLIENT
# ------------------------

# 1. installer nfs commons
# sudo apt-get install nfs-common
# 2. tester avec mount
# sudo mount -t nfs dinf-merle.dinf.fsci.usherbrooke.ca:/home/local/USHERBROOKE/ranj2004/Téléchargements/CoLab/ /media/node/DEI
# 3. ajouter à /etc/fstab
# dinf-merle.dinf.fsci.usherbrooke.ca:/srv/nfs  /media/colab  nfs  rsize=8192 and wsize=8192,noexec,nosuid,gid=media-node