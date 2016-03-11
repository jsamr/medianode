v0.3.1

- fix dans le script d'installation : vérification de l'existance de la commande redis-server
Z
v0.3.0

- gestion du fichier de meta par défaut à la racine d'un projet


v0.2.2 

- passage du package *promise* en paramètre d'un gestionaire d'authentification

v0.2.1 
 
- amélioration de la gestion d'erreurs  du gestionnaire mongo

v0.2.0 (First release)

- Compatible avec **CoLab** 0.2
- Implémentation du auth_handler mongo pour CoLab

v0.1.0 (draft)

- définition des routes serveur via express
- mécanisme d'authentification délégué (voir auth_handler dans la documentation)
- attribution de jetons (tokens) aux utilisateurs authentifiés donnant un accès aux médias
- routage intelligent avec déduction de routes par regex
- découverte de médias à partir d'une structure de dossier conventionnelle 
  - répertoire racine d'un projet
  - répertoire racine des expérimentations
  - répertoire racine d'une expérimentation
  - répertoire racine des médias propres à l'expérimentations
  - répertoire racine d'un point de captation
- serialisation des chemins dans une base redis pour optimiser le temps de requêtes médias multiples
  
