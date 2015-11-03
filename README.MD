# SERVEUR VIDEO/IMAGE/AUDIO POUR COLLABORATEURS DU DOMUS

## Apperçu
Le serveur est hébergé à l'adresse du serveur ftp Mignard. 
Il permet le streaming de médias compatibles avec les formats mime html5 [définis dans cette section](#mime_types).
La configuration se fait à partir du fichier config.json, à la racine du repo. 


## Sécurité et intégration
Le serveur implémente les CORS (Cross Origin Resources Sharing).
Pour autoriser une origine (une application web) à partager des médias venant de ce serveur, il va falloir
ajouter l'adresse de l'application web dans le tableau `crossOriginDomains`. Autrement, une erreur `403`
sera renvoyée au client. Cette sécurité fait qu'**un utilisateur ne peut pas se contenter de renseigner 
l'adresse du média dans le navigateur pour l'atteindre**.
 
## Configuration d'un projet
Un "projet" du point de vue du serveur est un simple répertoire racine. 
Il peut être configuré ainsi , dans l'entrée  `projects` du fichier de configuration : 

```json
    "ProjectName":{
      "rootDir":"my_project_dir",
      "expRegex":"*",
      "mediaDir":"videos/"
      "mediaRegex":"*.mp4",
      "authorizedDomains":[0,1]
    }
```
avec :

- `$ProjectName` : le nom du projet, utilisé dans les requêtes  
- `$rootDir` : le répertoire racine, relatif à `$baseDir` du fichier de configuration. **NE DOIT NI COMMENCER, NI SE TERMINER PAR /**
- `$expRegex` : l'epression régulière pour matcher les répertoires propres à une expérimentation à partir de `$rootDir` (descendants directs). 
- `$mediaDir` : le chemin permettant d'atteindre les médias depuis `$expdir`, peut être vide `""`,null ou non renseigné. **NE DOIT NI COMMENCER, NI SE TERMINER PAR /**
- `$mediaRegex`: l'expression régulière pour matcher les médias à partir de `$expDir` et `placeDir`
- `$authorizedDomains`: un tableau contenant l'index des domaines autorisés à diffuser ces médias. Les index sont ceux du tableau définit dans la propriété `crossOriginDomains` du fichier de configuration json.
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
4. Le répertoire associé au projet est-il accessible? Si oui, étape 5, si non, erreur http `404` [avec identifiant d'erreur "ROOT_DIR_NOT_FOUND"](#error_ids)
5. Le dossier associé à expérimentation `$ExpName`, matché avec `$expRegex$exp` existe-t-elle? Si oui, étape 6, si non, erreur http `404` [avec identifiant d'erreur "EXP_DIR_NOT_FOUND"](#error_ids)
6. Le dossier associé à l'endroit de captation `$placeDir` existe-t-il? Si oui, étape 7, si non erreur http `404` [avec identifiant d'erreur "PLACE_DIR_NOT_FOUND"](#error_ids)
7. Une $média matchée par `$mediaRegex` est-elle matchée à l'intérieur de `$placeDir`? Si oui, étape 8, si non erreur http `404` [avec identifiant d'erreur "MEDIA_NOT_FOUND"](#error_ids)
8. Renvoi d'une réponse http avec status `200` et `Content-Type : $type` ou `$type` est un [parmi la liste suivante](#mime_types).

<a name="API"></a>
## API

<a name="error_ids"></a>
### Codes d'erreurs
Ces codes d'erreurs sont distincts d'une erreur http. 
Le serveur va renvoyer une réponse de format mime `application/json` contenant
un string identifiant l'erreur rencontrée. **Un code d'erreur peut donc très bien s'ajouter à une erreur http!** 

- "UNAUTHORIZED_CLIENT" : Le client n'est pas autorisé, [politique CORS](https://developer.mozilla.org/fr/docs/HTTP/Access_control_CORS)
- "PROJECT_NOT_CONFIGURED" : Le projet n'est pas configuré sur le serveur (aucune entrée dans `projects` correspondante)
- "PROJECT_ROOT_MISSING" : Le projet est configuré, mais la propriété "rootDir" est manquante
- "ROOT_DIR_NOT_FOUND"  : Le répertoire racine du projet n'a pas été trouvé
- "EXP_DIR_NOT_FOUND"   : Le répertoire d'expérimentation n'a pas été trouvé
- "PLACE_DIR_NOT_FOUND" : Le répertoire associé à l'endroit de captation (ex `cuisine`) n'a pas été trouvé
- "MEDIA_NOT_FOUND"     : Aucun média n'a été trouvée dans le répertoire associé à l'endroit de captation.

### Requêtes
Les requêtes sont évaluées par routes ([path](http://tools.ietf.org/html/rfc3986#section-3.3)), et non par paramètres.

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
	
## Lancement du script

Le script `video-node.sh` doit se lancer avec deux paramètres : 
$1 : l'utilisateur
$2 : le groupe associé

**Les dossiers associés à chaque projet doivent être accessibles en lecture pour le groupe $2**