# SERVEUR MÉDIA SÉCURISÉ POUR COLLABORATEURS DU DOMUS

## Apperçu

- Permet le streaming de médias compatibles avec les formats mime html5 [définis dans cette section](#mime_types).
- La configuration se fait à partir du fichier config.json, à la racine du repo.
- Permet de "matcher" des fichiers à partir d'expressions régulières et d'associer [les routes média correspondantes](#medias).
- Léger et souple. Implémenté en javascript/coffeescript (nodejs)
- Sécurisé, avec [identification par tokens](#auth)
- Gestion des droits d'accès par
    - [application cliente](#applications)
    - [projet](#projects)
- Interfaçage avec n'importe quel mécanisme d'authentification, il suffit [d'écrire un petit module](#module)

## Conventions
 `$uneVariable` fait référence, suivant le contexte
- à un champs (json) du fichier de configuration, ex : `$uneVariable` fait référence à `"uneVariable":"un_string"`
- à une variable de route HTTP, ex : pour la route `/a/$uneVariable/`, et le chemin   `/a/uneValeurDeVariable/` `$uneVariable` fait référence à `"uneValeurDeVariable"`


## Intégration, configuration

<a name="applications"></a>
### Configuration d'une application ( $applications )
Pour clairement définir les accès à différents médias, le serveur permet la déclaration d'applications.
Les clients de ces applications auront des droits spécifiques, et des mécanismes d'authentification propres.
En voici un exemple :

```json
    "AppName":{
      "auth_handler":{
        "name": "some_auth_handler",
        "uri" :" some_data_store://some_address:some_port",
        "options":{},
        "reconnectAfter_s":6000
      },
      "projects":["ProjectName1","ProjectName2"],
      "enableMeta":true
    }
  }
```
avec :
- `$AppName`      : le nom de l'application, utilisée par la suite dans toutes les requêtes
- `$auth_handler` : le gestionnaire d'authentification, cf [la section dédiée](#module)
  - `$name`       : le nom du gestionnaire d'authentification utilisé, parmis ceux déclarés dans $auth_handlers
  - `$uri`        : le universal resource identifier qui permettra à au gestionnaire de se connecter à la bonne adresse
  - `$options`     : des options spécifiques au gestionnaire
  - `$reconnectAfter_s` : durée en secondes après laquelle media-node s'autorise à relancer le gestionnaire s'il est défaillant (entrepot injoignable par exemple).
- `$projects`     : les noms des projets auxquels auront accès les clients de l'application
- `$enableMeta`    : autorise la diffusion [de meta-informations](#meta-infos) lors des [place requests](#request_place) si et seulement si le projet a l'option `$supportMeta` activée. 


<a name="projects"></a>
### Configuration d'un projet ( $projects )
Un "projet" du point de vue du serveur est un simple répertoire racine.
Il peut être configuré ainsi , dans l'entrée  `projects` du fichier de configuration :

```json
    "ProjectName":{
      "rootDir":"my_project_dir",
      "expRegex":"*",
      "mediaDir":"videos/"
      "mediaRegex":"*.mp4",
      "supportMeta":true
    }
```
avec :

- `$ProjectName` : le nom du projet, utilisé dans les requêtes  
- `$rootDir` : le répertoire racine, relatif à `$baseDir` du fichier de configuration. **NE DOIT NI COMMENCER, NI SE TERMINER PAR /**
- `$expRegex` : l'epression régulière pour matcher les répertoires propres à une expérimentation à partir de `$rootDir` (descendants directs).
- `$mediaDir` : le chemin permettant d'atteindre les médias depuis `$expdir`, peut être vide `""`,null ou non renseigné. **NE DOIT NI COMMENCER, NI SE TERMINER PAR /**
- `$mediaRegex`: l'expression régulière pour matcher les médias à partir de `$expDir` et `placeDir`
- `$placeDir` : n'est pas configurable. Passé en paramètre d'une requête. Chacun de ces dossiers permets de distinguer différents médias suivant leur positionnement. (par exemple `cuisine`, `salle-manger` ...)
- `$supportMeta` : signale que [les meta-infos par fichier YAML](#meta-infos) sont activées si sa valeur est `true`

**REMARQUE IMPORTANTE** : la syntaxe des regexp est spécifique à une librairie utilisée pour le projet, [**veuillez vous renseigner ici.**](https://github.com/Carrooi/Node-FsFinder#path-mask)

- une regexp est contenur entre crochets `<[0-9]+>`
- la wildcard `*` équivaut à `<[0-9a-zA-Z/.-_ ]+>`

### Configuration du serveur ( $serv )
 Voici un exemple :

 ```json

 "serv":{
  "port":5000,
  "baseDir":"/home/dummy/medias/CoLab/",
  "disableAuth":true,
  "debug":true,
  "log":true,
  "delTokensOnShutdown":false,
  "streamer":{
     "maxAge":86400,
     "customMimes":{
       ".web-mp4":"video/mp4"
     }
   }
}
 ```  
 avec :

 - `$port` : le port d'écoute du serveur
 - `$baseDir` : le répertoire racine à partir duquel le serveur à accès. **Remarque** : seuls les répertoires appartenant au groupe `media-node`
 - `$disableAuth` : désactiver [le module d'authentification](#module). La route d'authentification ne sera pas disponible et les accès aux médias ne requèreront pas de token. **IMPORTANT** : n'est activable que lorsque `$debug`=true.
 - `$debug` : lancer le serveur en mode débug. Donne droit à l'activation de $disableAuth, et permet de rediriger les erreurs dans le corps de la réponse HTTP. Très pratique pour débugguer !
 - `$log` : active ou désactive la journalisation dans la console.
 - `$delTokensOnShutdown` : invalide les tokens lorsque le serveur s'arrête.
 - `$streamer.$customMimes` : Permet de mapper des associations de fichier avec [un mime-type](#mime_types) (défaut `{}`) .
 - `$streamer.$maxAge` : Indique au navigateur combien de secondes devrait-il conserver en câche le média téléchargé (défaut `3600`).

### Configuration des gestionnaires d'authentification ( $auth_handlers )

Confère [la section dédiée](#modules)

<a name="redis"></a>
### Configuration de Redis ( $redis )
**Redis doit être installé pour que le serveur fonctionne**
Exemple de configuration (config.json):
```json
"redis":{
  "socket":"/tmp/redis-media-node.sock",
  "expire_min":1440
}
```
Avec `$socket` le socket unix utilisé pour communiquer avec le video-node (ne devrait pas être modifié) et `$expire_min` la durée de vie d'un token en minutes.

## Dépendances

- Redis, v2.8 ou supérieur (minor releases)
- Node v0.10 et supérieurs 
- npm v1.3 et supérieurs   
- coffeescript v1.10 (**via npm** : `sudo npm install -g coffee-script@1.10` )

Exemple pour **debian, ubuntu...**  
> sudo apt-get install redis-server nodejs npm

**Problème connu avec nodejs**  
Pour certaines verison de node, il y a un conflit avec un packet node qui n'a rien à voir avec nodejs.  
Faites `whereis node`.   
**Si aucun répertoire n'apparait**, il faut faire un symlink de nodejs vers node :  
> sudo ln -s /usr/bin/nodejs /usr/sbin/node
> sudo ln -s /usr/bin/nodejs /usr/bin/node


<a name="API"></a>
## API

<a name="overview"></a>
**APPERÇU DE L'IMPLÉMENTATION d'UN ACCES A UN MDEDIA** : Lorsqu'une requête d'accès à un média est envoyée au serveur ([cf section API](#API)), la démarche pour diffuser le bon fichier va être la suivante.
On suppose que cette requête contient : `$ProjectName`, `$ExpName`, et `$placeDir`

1. Les paramètres `a` (application) et `t` existent-t-ils? Si oui, étape 2, sinon erreur http `422` [avec identifiant d'erreur "SESSION.BAD_QUERY"](#error_ids)
2. L'application est-elle enregistrée? Vérification avec le paramètre `a`. Si oui, étape 3, sinon erreur http `403` [avec identifiant d'erreur "INTERNAL.APPLICATION_NOT_REGISTERED"](#error_ids)
3. Le client est-il autorisé? Vérification avec le paramètre `t` (token). Si oui, étape 6, sinon, erreur http `403` [avec identifiant d'erreur "SESSION.FORBIDDEN"](#error_ids)
3. Le projet est-t-il configuré? Si oui, étape 4, si non, erreur http `500` [avec identifiant d'erreur "INTERNAL.PROJECT_NOT_CONFIGURED"](#error_ids)
4. La racine du projet est-elle configurée? Si oui, étape 4, si non, erreur http `500` [avec identifiant d'erreur "INTERNAL.PROJECT_ROOT_MISSING"](#error_ids)
5. L'application a-t-elle le droit d'accéder au projet `$ProjectName` ? Si oui, étape 5, sinon, erreur http `403` [avec identifiant d'erreur "SESSION.PROJECT_ACCESS_FORBIDDEN"](#error_ids)
6. Le répertoire associé au projet est-il accessible? Si oui, étape 7, si non, erreur http `404` [avec identifiant d'erreur "SESSION.ROOT_DIR_NOT_FOUND"](#error_ids)
7. Le dossier associé à expérimentation `$ExpName`, matché avec `$expRegex$exp` existe-t-elle? Si oui, étape 8, si non, erreur http `404` [avec identifiant d'erreur "SESSION.EXP_DIR_NOT_FOUND"](#error_ids)
8. Le dossier associé à l'endroit de captation `$placeDir` existe-t-il? Si oui, étape 9, si non erreur http `404` [avec identifiant d'erreur "SESSION.PLACE_DIR_NOT_FOUND"](#error_ids)
9. Une $média matchée par `$mediaRegex` est-elle matchée à l'intérieur de `$placeDir`? Si oui, étape 10, si non erreur http `404` [avec identifiant d'erreur "SESSION.MEDIA_NOT_FOUND"](#error_ids)
10. Renvoi d'une réponse http avec status `200`, `Content-Type : $type` ou `$type` est un [parmi la liste suivante](#mime_types) et évidemment le contenu du média dans le body.

<a name="error_ids"></a>
### Codes d'erreurs
Ces codes d'erreurs sont distincts d'une erreur http.
Le serveur va renvoyer une réponse de format mime `application/json` contenant
un string identifiant l'erreur rencontrée. Ce string peut être récupéré via JSON.parse(response) en javascript par exemple.  
**Un code d'erreur peut donc très bien s'ajouter à une erreur http!**

| Code                                  |  Signification |
|:--------------------------------------|:---------------|
| "INTERNAL.APPLICATION_NOT_REGISTERED" | L'application n'est pas enregistrée |
| "INTERNAL.REDIS_INTERNAL_ERROR"       | Redis (db de cache) a rencontré un problème |
| "INTERNAL.PROJECT_NOT_CONFIGURED"     | Le projet n'est pas configuré sur le serveur (aucune entrée dans `projects` correspondante) |
| "INTERNAL.PROJECT_ROOT_MISSING"       | Le projet est configuré, mais la propriété "rootDir" est manquante |
| "AUTH_FAILURE.HANDLER_INTERNAL_ERROR" | Le gestionnaire d'authentification a rencontré une erreur, probablement en contactant l'entrepot distant |
| "AUTH_FAILURE.BAD_CREDENTIALS"        | Le gestionnaire d'authentification a indiqué que les 'credentials' n'avaient pas le format escomptée |
| "AUTH_FAILURE.FORBIDDEN"              | Le gestionnaire d'authentification a indiqué que les 'credentials' étaient invalides |
| "SESSION.FORBIDDEN"                   | L'identification par token a échoué (token expiré, token invalide)  |
| "SESSION.APP_MISSING_PREROGATIVES"    | Le projet n'est pas référencé dans la configuration de l'application |
| "SESSION.BAD_QUERY"                   | La arguments 'query' sont manquants ou mal formés  |
| "SESSION.ROOT_DIR_NOT_FOUND"          | Le répertoire racine du projet n'a pas été trouvé |
| "SESSION.EXP_DIR_NOT_FOUND"           | Le répertoire d'expérimentation n'a pas été trouvé |
| "SESSION.PLACE_DIR_NOT_FOUND"         | Le répertoire associé à l'endroit de captation (ex `cuisine`) n'a pas été trouvé |
| "SESSION.MEDIA_NOT_FOUND"             | Aucun média n'a été trouvée dans le répertoire associé à l'endroit de captation. |

### Requêtes
Les requêtes sont évaluées par routes ([path](http://tools.ietf.org/html/rfc3986#section-3.3)).
**Si l'authentification est activée, elles doivent contenir des paramètres d'identification, cf [cette section](#identification)**

<a name="request_place"></a>
#### [REQUEST_PLACES] Récupération de la liste des endroits de captation (places)
Cette requête renvoie :

**Si le client a le droit, et le projet correctement configuré, une réponse avec status `200` sous format application/json**

- Une liste sous forme de tableau des endroits de captation trouvé pour une expérimentation donnée si le dossier d'expérimentation existe. **ATTENTION** Le serveur ne vérifie pas si ces dossiers contiennent un média. Chaque endroit de captation est un objet contenant les champs suivants:
  - `place` : le lieu de captation, c-à-d le nom du dossier
  - `fileFound` : `true` si un fichier a été trouvé, `false` sinon
  - `meta` : **optionnel** Si l'option `$supportMeta` est activée pour le projet **et** l'option `$enableMeta` est activée pour l'application : 
    - un objet contenant les champs [du fichier YAML](#meta-files) si un tel fichier existe
    - `null` sinon
- Un [code d'erreur](#error_ids) si un problème est rencontré

**Sinon**

- Une erreur http `500` avec [code d'erreur  "INTERNAL.PROJECT_NOT_CONFIGURED"](#error_ids)
- ou Une erreur http `500` avec [code d'erreur  "INTERNAL.PROJECT_NOT_CONFIGURED"](#error_ids)
- ou Une erreur http `403` avec [code d'errreur "SESSION.FORBIDDEN"](#error_ids)


Elle a la forme suivante : `/i/$ProjectName/$ExpName` ou  :

- `$ProjectName` correspond au `$ProjectName` du fichier de configuration
- `$ExpName` est le nom de l'expérimentation. ça n'est pas le nom complêt puisque le dossier va être matché avec "$expRegex$ExpName"

<a name="medias"></a>
#### [REQUEST_MEDIA] Récupération d'un media

**REMARQUE IMPORTANTE** : il est très recommandé de faire une [REQUEST_PLACES](#request_place) d'abord, pour s'assurer des  endroits de captation disponibles.

**Si le client a le droit, et le projet correctement configuré**

- Si le media est trouvé, une réponse avec status `200` et `Content-Type : $type` ou `$type` est un [parmi la liste suivante](#mime_types)
- Sinon, une réponse avec status `200` et `Content-Type : application/json` contenant un [code d'erreur](#error_ids)

**Sinon**

- Une erreur http `500` avec [code d'erreur  "INTERNAL.PROJECT_NOT_CONFIGURED"](#error_ids)
- ou Une erreur http `500` avec [code d'erreur  "INTERNAL.PROJECT_NOT_CONFIGURED"](#error_ids)
- ou Une erreur http `403` avec [code d'errreur "SESSION.FORBIDDEN"](#error_ids)

Elle a la forme suivante : `/v/$ProjectName/$ExpName/$placeDir` ou  :

- `$ProjectName` correspond au `$ProjectName` du fichier de configuration
- `$ExpName` est le nom de l'expérimentation. ça n'est pas le nom complêt puisque le dossier va être matché avec "$expRegex$ExpName"
- `$placeDir` est le nom de l'endroit de captation (`cuisiniere`,`salle-de-bain` ...)

[Confère cette description pour connaitre le détail de l'implémentation.](#overview)

## Sécurité
<a name="auth"></a>
### Authentification par 'credentials'

Si l'authentification est activée ( `$disableAuth = false` dans le fichier de configuration ), le client va devoir s'authentifier auprès du serveur vidéo.
**Il est important de noter que le mécanisme d'authentification est à la charge du développeur souhaitant utiliser le serveur vidéo**.
Il devra écrire un petit module en javascript de quelques lignes permettant de valider les 'credentials' du client  
( typiquement en contactant la base de donnée utilisée par l'application hôte du développeur qui souhaite intégrer les vidéos ), voire [la section dédiée pour l'implémentation](#module).

<a name="auth_req"></a>
#### Requête (POST HTTP/1.1)

Il faut envoyer une requête :

- `POST`
- sur le chemin `/auth/c/$applicationName`
- de `Content-Type` mime `application/x-www-form-urlencoded`
- dont le corps (`body`) contient les 'credentials' [url-encodés](https://en.wikipedia.org/wiki/Percent-encoding#The_application.2Fx-www-form-urlencoded_type) qui seront transmis au [gestionnaire d'authentification](#module)

avec  :

- `$applicationName` le nom de l'application déclarée de le fichier de configuration JSON,
- 'credentials' les paramètres d'authentification qui seront passés au gestionnaire d'authentification de l'application (`$auth_handler` dans le fichier de configuration), une fois désérialisés.

**Remarque** : la raison du mime type `application/x-www-form-urlencoded` est que
les navigateurs implémentent aujourd'hui des politiques de sécurité contraignantes, les CORS, qui interdisent des requêtes `POST` de mime type `application/json` sur des domaines croisés.
Cf [cet article du MDN pour référence](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS)

#### Réponse HTTP/1.1
La réponse de de type mime `application/json`

**Si l'authentification a réussie :** Renvoie un objet json contenant deux `string`s :

- l'un nommé **token**`, à conserver pour l'identification des requêtes  (cf section suivante)
- l'autre nommé **epoch_s**, contenant la date d'expiration du token en [temps epoch (secondes)](https://en.wikipedia.org/wiki/Unix_time)  

**Si l'authentification a échouée :** Renvoie un code d'erreur au format json dont le préfixe est `AUTH_FAILURE`, [confère la section dédiée pour en connaître la signification](#error_ids).

<a name="auth_token"></a>

### Authentification par token
Si un token est encore valide alors que le client relance l'application web utilisatrice du serveur vidéo, il n'est pas nécessaire de se
réauthentifier par 'credentials'. Pour s'assurer que le token est toujours valide côté serveur (qu'il n'y a pas eu de redémarrage brutal ou un problème rencontré par redis par exemple), une requête peut être envoyée.

#### Requête (POST HTTP/1.1)
La requête doit être :
- `POST`
- sur le chemin `/auth/t/$applicationName`
- de `Content-Type` mime `application/x-www-form-urlencoded`
- dont le corps (`body`) contient un paramêtre `token=mytoken` [url-encodés](https://en.wikipedia.org/wiki/Percent-encoding#The_application.2Fx-www-form-urlencoded_type) dont le serveur va s'assurer de la validité en contactant l'entrepot redis.

avec
- `$applicationName` le nom de l'application cliente.
- `my_token` le token renvoyé précédement par une authentification par 'credentials'.

#### Réponse HTTTP/1.1

Si le token est valide :
- une réponse vide avec status=200 (OK)
Sinon
- une réponse avec [code d'erreur "SESSION.FORBIDDEN"](#error_ids) et status=403

<a name="identification"></a>
### Identification

Une requête sur un chemin media `/m/*` ou info `/i/*` doit nécessairement contenir deux paramètres d'identification, **a** (application) et **t** (token)
Exemple d'url complète : `http://serveur-media/m/MY_PROJECT/MY_EXP/MY_PLACE?a=my_app&t=my_token`
avec `my_app` le nom de l'application enregistrée dans le fichier de configuration et `my_token` le token obtenu [à l'authentification](#auth).

<a name="module"></a>
## Modules / Gestionnaires d'authentification
Idéalement, les modules devraient être chargés avec npm. Mais nous n'avons pas de dépot npm propre au laboratoire...

Un module est un simple fichier javascript **ou** coffeescript qui a pour role d'authentifier un client.



### Prérequis

- Le module doit être définit dans le dossier `auth_handler`
- Dans un fichier `mon_module.js` ou `mon_module.coffee`
- Le nom du fichier doit être déclaré dans le fichier de configuration, tableau `$auth_handlers`, sans extension.
- **ses dépendances** doivent être déclarées dans le fichier de configuration de npm, `package.conf`, paramètre `$dependencies`. [Plus d'infos sur semver (la syntaxe pour déclarer les versions candidates) ici](http://semver.npmjs.com/).

### Conseils
- Les dépendances typiques seront des drivers pour l'entrepot de données utilisé. Faites une recherche "npm postgresql" dans google par exemple pour trouver un driver postegresql.
- Utilisez [lodash](https://lodash.com/), qui est déjà incluse dans le projet, une excellente lib fonctionnelle.


### Spécifications

Rien de mieux qu'un exemple javascript :
```javascript
var postgres=require("node-postgres"); // juste pour l'exemple, mais ça peut être n'importe quelle package npm
// Du code pour déclarer des fonctions privées etc...

// exemple d'uri : "postgres://username:password@localhost/database"
// options est un objet javascript
module.exports = function(uri,options){
    // DOIT renvoyer un objet ayant EXACTEMENT (ni plus ni moins) les méthodes suivantes
    return {
        assertCredentials:function(credentials){
          var areCredentialsWellFormatted=false;
          // Du code pour s'assurer que les credentials sont dans le format attendu
          // et assigner true à isCredentialWellFormatted le cas échéant
          return areCredentialsWellFormatted;
        },
        start:function(){
            // Du code pour ouvrir la connexion avec un postgresql
            // Cette méthode peut lever une erreur, si options n'est pas dans le format attendu par exemple
            // Garder à l'esprit que cette fonction peut être appellée plusieurs fois au cours d'une execution du serveur.
            // En effet, le serveur essaiera de relancer le gestionnaire tous les $reconnectAfter_s lorsqu'il rencontre une erreur
        },
        stop:function(){
            // Du code pour fermer proprement la connexion avec postgresql
            // Cette méthode peut lever une erreur.
            // Garder à l'esprit que cette fonction peut être appellée plusieurs fois au cours d'une execution du serveur.
        },
        authClientSync : function(credentials){
            var success=false
            // Du code pour authentifier l'utilisateurs avec 'credentials'
            // et assigner true à success si l'authentification réussit
            // Cette méthode doit lever une erreur si un problème est rencontré avec le driver
            return success;

        }
    }
}
```
Comme vous pouvez le voir la signature du module est très simple.


**Les points clés à comprendre :**

- `uri` et `options` sont directement issus du champs `$auth_handler` de la ou des application(s) qui vont utiliser le module.
- `credentials` est un objet qui a été dé-urlencodé depuis [la requête d'authentification](#auth)
- la fonction `authClientSync` **ne doit pas** catcher d'erreur, c'est le serveur en amont qui s'en chargera, et renverra [un code d'erreur "AUTH_FAILURE.HANDLER_INTERNAL_ERROR"](#error_ids).
- lorsque la fonction `assertCredentials` renvoit `false`, le serveur renverra [un code d'erreur "AUTH_FAILURE.BAD_CREDENTIALS"](#error_ids)
- lorsque la fonction `authClientSync` renvoit `true`, le serveur va générer un token et le renvoyer au client. Dans le cas contraire, elle renverra [un code d'erreur "AUTH_FAILURE.FORBIDDEN"](#error_ids).

Eh voià !

<a name="meta-infos"></a>
## Meta-infos
Lorsque les meta-infos sont activées, les dossiers contenant les medias **peuvent** contenir un fichier `meta.yml` [respectant le format YAML](https://fr.wikipedia.org/wiki/YAML)


Les quatre champs supportés par défaut sont les suivant (exemple) :
 
```yaml
---
error : "Le media est corrompu"
warning: "Le media ne fonctionne pas de X min à Y min"
comments: "Blablabla"
soundQ: 0
```

- `$error` : Le fichier ne peut être servit depuis le serveur, il est inexistant ou corrompu. 
- `$warning` : Le fichier est servit mais n'est pas totalement intègre
- `$comments` : commentaire divers
- `$soundQ` : si le media est de type vidéo ou audio, qualité sonnore allant de 0 (pas de son) à 3 (bonne qualité)

Bien entendu, libre à l'utilisateur de rajouter des attributs.  
Ils seront tous disponibles [dans la requête d'information](#request_place).

<a name="mime_types"></a>
## Types mimes

Voici les types supportés par le serveur.
**ATTENTION** : ça ne signifie pas que le client pourra nécessairement les lire.

	".swf": "application/x-shockwave-flash",
	".flv": "video/x-flv",
	".f4v": "video/mp4",
	".f4p": "video/mp4",
	".mp4": "video/mp4",
	".asf": "video/x-ms-asf",
	".asr": "video/x-ms-asf",
	".asx": "video/x-ms-asf",
	".avi": "video/x-msvideo",
	".mpa": "video/mpeg",
	".mpe": "video/mpeg",
	".mpeg": "video/mpeg",
	".mpg": "video/mpeg",
	".mpv2": "video/mpeg",
	".mov": "video/quicktime",
	".movie": "video/x-sgi-movie",
	".mp2": "video/mpeg",
	".qt": "video/quicktime",
	".mp3": "audio/mpeg",
	".wav": "audio/x-wav",
	".aif": "audio/x-aiff",
	".aifc": "audio/x-aiff",
	".aiff": "audio/x-aiff",
	".jpe": "image/jpeg",
	".jpeg": "image/jpeg",
	".jpg": "image/jpeg",
	".png" : "image/png",
	".svg": "image/svg+xml",
	".tif": "image/tiff",
	".tiff": "image/tiff",
	".gif": "image/gif",
	".webm": "video/webm",
	".m3u8": "application/x-mpegurl",
	".ts": "video/mp2t",
	".ogg": "video/ogg"


## Lancement du script scripts/media-node.sh

**Conditions au lancement**

- Les [dépendance](#deps) doivent avoir été installées
- Le script `scripts/install.sh` doit avoir été lancé en superuser
- L'utilisateur du script doit appartenir au groupe unix `media-node`
- Les répertoires et descendants associés aux différents projets doivent appartenir au groupe unix `media-node`

**Conditions au fonctionnement**

- Le port configuré `$port` doit être ouvert sur le serveur
- Si l'authentification est activée, s'assurer que les entrepots distants (mongo, postgresql ...) sont accessibles.
Si les gestionnaires d'authentification n'ont pas accès, le serveur se lancera quand même, et retentera une connexion régulièrement suivant l'application (interval minimal de `$applications$appName$auth_handler$reconnectAfter_s`, 6000s par défaut)

**Ajout de l'utilisateur/groupe au groupe media-node**

> `sudo usermod -a -G media-node nom_utilisateur_ou_groupe`


## Bugs connus

- Si un fichier dont le nom matche l'expression régulière `projects.$.mediaRegex` est corrompus mais existe, il sera tout de même conservé en cache.
Il faudra dans ce cas redémarrer le serveur. 