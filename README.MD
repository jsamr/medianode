# SERVEUR VIDEO/IMAGE/AUDIO POUR COLLABORATEURS DU DOMUS

## Apperçu
Le serveur est hébergé à l'adresse du serveur ftp Mignard. 
Il permet le streaming de médias compatibles avec les formats mime html5 [définis dans cette section](#mime_types).
La configuration se fait à partir du fichier config.json, à la racine du repo. 


## Intégration

### Tokens
Le serveur utilise **redis** comme cache pour des token de connexion. Cf [la section dédiée](#redis).
 
## Configuration d'une application
Pour clairement définir les accès à différents médias, le serveur permet la déclaration d'applications.
Les clients de ces applications auront des droits spécifiques, et des mécanismes d'authentification propres. 
En voici un exemple : 
```json
    "AppName":{
      "auth_handler":{
        "name": "some_auth_handler",
        "uri" :" some_data_store://some_address:some_port",
        "options":{}
      },
      "projects":["ProjectName"]
    }
  }
```
avec : 
- `$AppName`      : le nom de l'application, utilisée par la suite dans toutes les requêtes 
- `$auth_handler` : le gestionnaire d'authentification, confère [la section dédiée](#module)
 
## Configuration d'un projet
Un "projet" du point de vue du serveur est un simple répertoire racine. 
Il peut être configuré ainsi , dans l'entrée  `projects` du fichier de configuration : 

```json
    "ProjectName":{
      "rootDir":"my_project_dir",
      "expRegex":"*",
      "mediaDir":"videos/"
      "mediaRegex":"*.mp4",
    }
```
avec :

- `$ProjectName` : le nom du projet, utilisé dans les requêtes  
- `$rootDir` : le répertoire racine, relatif à `$baseDir` du fichier de configuration. **NE DOIT NI COMMENCER, NI SE TERMINER PAR /**
- `$expRegex` : l'epression régulière pour matcher les répertoires propres à une expérimentation à partir de `$rootDir` (descendants directs). 
- `$mediaDir` : le chemin permettant d'atteindre les médias depuis `$expdir`, peut être vide `""`,null ou non renseigné. **NE DOIT NI COMMENCER, NI SE TERMINER PAR /**
- `$mediaRegex`: l'expression régulière pour matcher les médias à partir de `$expDir` et `placeDir`
- `$placeDir` : n'est pas configurable. Passé en paramètre d'une requête. Chacun de ces dossiers permets de distinguer différentes médias suivant leur positionnement. (par exemple `cuisine`, `salle-manger` ...) 


**REMARQUE IMPORTANTE** : la syntaxe des regexp est spécifique à une librairie utilisée pour le projet, [**veuillez vous renseigner ici.**](https://github.com/Carrooi/Node-FsFinder#path-mask)

- une regexp est contenur entre crochets `<[0-9]+>`
- la wildcard `*` équivaut à `<[0-9a-zA-Z/.-_ ]+>` 

<a name="overview"></a>
**APPERÇU DE L'IMPLÉMENTATION** : Lorsqu'une requête d'accès à un média est envoyée au serveur ([cf section API](#API)), la démarche pour diffuser le bon fichier va être la suivante.
On suppose que cette requête contient : `$ProjectName`, `$ExpName`, et `$placeDir`

1. Le client est-il autorisé? Vérification avec le champs `$crossOriginDomains`. Si oui, étape 2, si non, erreur http `403`
2. Le client a-t-il droit d'accéder au projet `$ProjectName`? Vérification avec le champs `$authorizedDomains`. Si oui, étape 3, si non, erreur http `403` 
3. Le projet existe-t-il dans le fichier de configuration? Si oui, étape 4, si non, erreur http `500`
4. Le répertoire associé au projet est-il accessible? Si oui, étape 5, si non, erreur http `404` [avec identifiant d'erreur "SESSION.ROOT_DIR_NOT_FOUND"](#error_ids)
5. Le dossier associé à expérimentation `$ExpName`, matché avec `$expRegex$exp` existe-t-elle? Si oui, étape 6, si non, erreur http `404` [avec identifiant d'erreur "SESSION.EXP_DIR_NOT_FOUND"](#error_ids)
6. Le dossier associé à l'endroit de captation `$placeDir` existe-t-il? Si oui, étape 7, si non erreur http `404` [avec identifiant d'erreur "SESSION.PLACE_DIR_NOT_FOUND"](#error_ids)
7. Une $média matchée par `$mediaRegex` est-elle matchée à l'intérieur de `$placeDir`? Si oui, étape 8, si non erreur http `404` [avec identifiant d'erreur "SESSION.MEDIA_NOT_FOUND"](#error_ids)
8. Renvoi d'une réponse http avec status `200` et `Content-Type : $type` ou `$type` est un [parmi la liste suivante](#mime_types).

<a name="API"></a>
## API

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
| "AUTH_FAILURE.HANDLER_UNAVAILABLE"    | Le gestionnaire d'authentification n'a pas pu contacter l'entropot distant (mongodb par exemple) |
| "AUTH_FAILURE.HANDLER_INTERNAL_ERROR" | Le gestionnaire d'authentification a rencontré une erreur |
| "AUTH_FAILURE.FORBIDDEN"              | Le gestionnaire d'authentification a indiqué que les 'credentials' étaient invalides |
| "SESSION.FORBIDDEN"                   | L'identification par token a échoué (token expiré, token invalide)  |
| "SESSION.BAD_QUERY"                   | La arguments 'query' sont manquants ou mal formés  |
| "SESSION.ROOT_DIR_NOT_FOUND"          | Le répertoire racine du projet n'a pas été trouvé |
| "SESSION.EXP_DIR_NOT_FOUND"           | Le répertoire d'expérimentation n'a pas été trouvé |
| "SESSION.PLACE_DIR_NOT_FOUND"         | Le répertoire associé à l'endroit de captation (ex `cuisine`) n'a pas été trouvé |
| "SESSION.MEDIA_NOT_FOUND"             | Aucun média n'a été trouvée dans le répertoire associé à l'endroit de captation. |

### Requêtes
Les requêtes sont évaluées par routes ([path](http://tools.ietf.org/html/rfc3986#section-3.3)). 
**Si l'authentification est activée, elles doivent contenir des paramètres d'identification, cf [cette section](#identification) 

<a name="request_place"></a>
#### [REQUEST_PLACES] Récupération de la liste des endroits de captation (places) 
Cette requête renvoie :
   
**Si le client a le droit, et le projet correctement configuré, une réponse avec status `200` sous format application/json**

- Une liste sous forme de tableau des endroits d'acquisition trouvé pour une expérimentation donnée si le dossier d'expérimentation existe. **ATTENTION** Le serveur ne vérifie pas si ces dossiers contiennent un média. 
- Un [code d'erreur](#error_ids) si un problème est rencontré
  
**Sinon**

- Une erreur http `500` avec [code d'erreur  "PROJECT_NOT_CONFIGURED"](#error_ids)
- ou Une erreur http `500` avec [code d'erreur  "PROJECT_ROOT_MISSING"](#error_ids)
- ou Une erreur http `403` avec [code d'errreur "UNAUTHORIZED_CLIENT"](#error_ids)

Elle a la forme suivante : `/i/$ProjectName/$ExpName` ou  :

- `$ProjectName` correspond au `$ProjectName` du fichier de configuration
- `$ExpName` est le nom de l'expérimentation. ça n'est pas le nom complêt puisque le dossier va être matché avec "$expRegex$ExpName"

#### [REQUEST_MEDIA] Récupération d'un media 

**REMARQUE IMPORTANTE** : il est très recommandé de faire une [REQUEST_PLACES](#request_place) d'abord, pour s'assurer des  endroits de captation disponibles. 

**Si le client a le droit, et le projet correctement configuré

- Si le media est trouvé, une réponse avec status `200` et `Content-Type : $type` ou `$type` est un [parmi la liste suivante](#mime_types)
- Sinon, une réponse avec status `200` et `Content-Type : application/json` contenant un [code d'erreur](#error_ids) 
  
**Sinon**

- Une erreur http `500` avec [code d'erreur  "PROJECT_NOT_CONFIGURED"](#error_ids)
- ou Une erreur http `500` avec [code d'erreur  "PROJECT_ROOT_MISSING"](#error_ids)
- ou Une erreur http `403` avec [code d'errreur "UNAUTHORIZED_CLIENT"](#error_ids)

Elle a la forme suivante : `/v/$ProjectName/$ExpName/$placeDir` ou  :

- `$ProjectName` correspond au `$ProjectName` du fichier de configuration
- `$ExpName` est le nom de l'expérimentation. ça n'est pas le nom complêt puisque le dossier va être matché avec "$expRegex$ExpName"
- `$placeDir` est le nom de l'endroit de captation (`cuisiniere`,`salle-de-bain` ...)

[Confère cette description pour connaitre le détail de l'implémentation.](#overview)

## Sécurité 
<a name="auth"></a>
### Authentification

Si l'authentification est activée ( `$disableAuth = false` dans le fichier de configuration ), le client va devoir s'authentifier auprès du serveur vidéo.
**Il est important de noter que le mécanisme d'authentification est à la charge du développeur souhaitant utiliser le serveur vidéo**. 
Il devra écrire un petit module en javascript de quelques lignes permettant de valider les 'credentials' du client  
( typiquement en contactant la base de donnée utilisée par l'application hôte du développeur qui souhaite intégrer les vidéos ), voire [la section dédiée pour l'implémentation](#module).

<a name="auth_req"></a>
#### Requête (POST HTTP/1.1)

Il faut envoyer une requête :
 
- `POST` 
- sur le chemin `/auth/my_app/`
- de `Content-Type` mime `application/x-www-form-urlencoded`
- dont le corps (`body`) contient les 'credentials' [url-encodée](https://en.wikipedia.org/wiki/Percent-encoding#The_application.2Fx-www-form-urlencoded_type) qui seront transmis au [gestionnaire d'authentification](#module)

avec  :

- `$my_app` le nom de l'application déclarée de le fichier de configuration JSON,
- 'credentials' les paramètres d'authentification qui seront passé au gestionnaire d'authentification de l'application (`$auth_handler` dans le fichier de configuration), une fois désérialisés. 

**Remarque** : la raison du mime type `application/x-www-form-urlencoded` est que
les navigateurs implémentent aujourd'hui des politiques de sécurité contraignantes, les CORS, qui interdisent des requêtes `POST` de mime type `application/json` sur des domaines croisés. 
Cf [cet article du MDN pour référence](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS)

#### Réponse HTTP/1.1
La réponse de de type mime `application/json`

**Si l'authentification a réussie :** Renvoie un objet json contenant deux `string`s : 

- l'un nommé **token**`, à conserver pour l'identification des requêtes  (cf section suivante)
- l'autre nommé **epoch**, contenant la date d'expiration du token en [temps epoch](https://en.wikipedia.org/wiki/Unix_time)  

**Si l'authentification a échouée :** Renvoie un code d'erreur au format json dont le préfixe est `AUTH_FAILURE`, [confère la section dédiée pour en conaitre la signification](#error_ids).

<a name="identification"></a>
### Identification

Une requête sur un chemin media `/m/*` ou info `/i/*` doit nécessairement contenir deux paramètres d'identification, **a** (application) et **t** (token)
Exemple d'url complète : `http://serveur-media/m/MY_PROJECT/MY_EXP/MY_PLACE?a=my_app&t=my_token`
avec `my_app` le nom de l'application enregistrée dans le fichier de configuration et `my_token` le token obtenu [à l'authentification](#auth).

<a name="module"></a> 
## Module 
** Le serveur vidéo se contentera de charger ce module, d'appeler la méthode `authAsync` .... ]**  
 
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
	

<a name="redis"></a>
## Redis
Redis doit être configuré (cf le fichier de config redis.conf) pour communiquer via sockets unix accessible dans le fichier "/tmp/redis.sock"


## Lancement du script


Le script `video-node.sh` doit se lancer avec deux paramètres : 
$1 : l'utilisateur
$2 : le groupe associé

**Les dossiers associés à chaque projet doivent être accessibles en lecture pour le groupe $2**