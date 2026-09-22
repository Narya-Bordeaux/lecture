# Commandes

Ce que l'on tape pour lancer, vérifier et construire le projet. Une commande
n'entre ici que le jour où elle a réellement été exécutée avec succès — ce
document n'est pas une liste d'intentions.

Chaque commande est donnée avec ce qu'elle exige et ce qu'elle produit, parce
qu'une commande sans son contexte finit par être recopiée au mauvais endroit.

## Lancer

**Une saveur Gradle ne choisit pas le point d'entrée Dart.** `--flavor` et `-t`
sont deux options indépendantes, que rien n'oblige à apparier. Elles vont
toujours ensemble, dans ces deux combinaisons et pas d'autres :

```bash
# Le jeu, celui qui sera publié
flutter run --flavor jeu -t lib/main.dart

# L'outil d'auteur, qui cale les zones sur l'illustration
flutter run --flavor auteur -t lib/main_author.dart
```

**Exige** : un poste équipé du SDK Android et un appareil ou un émulateur
connecté. Ces commandes ne fonctionnent pas en session cloud, faute de SDK.

**Produit** : deux applications distinctes, qui cohabitent sur l'appareil —
« Grisbie » et « Grisbie auteur ». L'outil d'auteur porte l'identifiant suffixé
`fr.naryabordeaux.grisbie.auteur` ; voir `Noms_et_identifiants.md`.

Les saveurs existant, **`--flavor` est obligatoire** : `flutter run` ou
`flutter build` sans elle s'arrête en le disant.

Deux garde-fous couvrent l'appariement, chacun dans un sens. `lib/main_author.dart`
vérifie au démarrage la constante `appFlavor` et refuse de s'ouvrir sous la
saveur du jeu, où il n'aurait pas sa configuration Firebase et aurait échoué plus
tard et plus loin. Dans l'autre sens, celui qui compte, le suffixe suffit : un jeu
compilé par erreur sous la saveur auteur ne porte pas l'identifiant publié, il est
donc impubliable et l'erreur reste sans conséquence.

## Lancer l'outil d'auteur avec le dépôt distant

Les valeurs du projet Firebase se passent **au lancement**, jamais dans le
dépôt. Elles sont compilées *dans* le build et ne sont stockées nulle part :
**chaque lancement doit les porter**. Sans elles, l'outil se lance et
enregistre en local : rien ne casse, la connexion n'est simplement pas
proposée.

D'où le fichier, une fois pour toutes. Recopier `.env.example` en `.env`, y
coller les valeurs, puis :

```
flutter run --flavor auteur -t lib/main_author.dart --dart-define-from-file=.env
```

Dans un navigateur, remplacer `--flavor auteur` par `-d chrome` : les saveurs
n'existent pas hors Android.

```
flutter run -d chrome -t lib/main_author.dart --dart-define-from-file=.env
```

`.env` est exclu par le `.gitignore`, qui n'admet que `.env.example` : rien de
réel n'entre dans le dépôt, qui part en open source.

**La forme longue marche aussi**, si l'on préfère ne pas laisser de fichier —
mais **tout sur une seule ligne**, et c'est important : le `\` de fin de ligne
est une continuation **bash**, que PowerShell et `cmd` ne connaissent pas.
Collée sur plusieurs lignes dans un terminal Windows, la commande se lance
sans aucune de ses valeurs — Chrome s'ouvre, l'outil tourne, et la connexion
n'est pas proposée. Rien ne signale l'erreur.

```
flutter run -d chrome -t lib/main_author.dart --dart-define=GRISBIE_FIREBASE_API_KEY=… --dart-define=GRISBIE_FIREBASE_APP_ID=… --dart-define=GRISBIE_FIREBASE_PROJECT_ID=grisbie-43ee9 --dart-define=GRISBIE_FIREBASE_SENDER_ID=… --dart-define=GRISBIE_FIREBASE_BUCKET=grisbie-43ee9.firebasestorage.app --dart-define=GRISBIE_FIREBASE_AUTH_DOMAIN=grisbie-43ee9.firebaseapp.com
```

**Comment savoir que les valeurs sont arrivées** — sans les lire nulle part :
l'écran d'accueil porte une **tuile de compte** (« Se connecter pour travailler
sur le dépôt »). Valeurs absentes ou incomplètes, `AuthorRemote.connect()` rend
`null` et la tuile **n'existe pas du tout** : une capacité manquante ne
s'annonce pas sur un écran de travail. Pas de tuile, donc pas de valeurs.

**`-d` désigne un *device*, et Chrome en est un** — au même titre qu'un
téléphone branché en USB. Il n'y a donc rien à ouvrir ni à saisir dans une
barre d'adresse : la commande compile, démarre un serveur local et ouvre
elle-même la fenêtre. `flutter devices` dit si Chrome est vu.

La commande se tape dans un terminal placé sur le projet — l'onglet *Terminal*
d'Android Studio y est déjà. Pour passer par l'interface plutôt que par la
ligne de commande : sélecteur d'appareil → *Chrome (web)*, et
`--dart-define-from-file=.env` dans `Run → Edit Configurations… → Additional
run args`. Là non plus, pas de `\` : ce champ n'est pas un terminal.

**Exige** : le projet `grisbie-43ee9` configuré — la marche à suivre est dans
`TODO.md`. `AUTH_DOMAIN` ne sert qu'au web ; les cinq autres sont obligatoires,
et l'outil nomme celles qui manquent.

Les valeurs ci-dessus sont **à relever dans la console**, pas à deviner : le nom
du bucket notamment diffère selon l'âge du projet. Web et Android ont chacun
leur `API_KEY` et leur `APP_ID`, le reste est commun.

**Produit** : l'écran d'accueil de l'outil propose de se connecter. Une fois
connecté, « Enregistrer » dépose le contenu sur le dépôt au lieu de l'appareil,
et l'accueil affiche l'**UID** — celui que la règle du bucket doit nommer.

**Éprouvé le 22 septembre 2026**, dans Chrome : connexion, dépôt du contenu et
relecture. L'outil liste les aventures du dépôt et les ouvre.

## Autoriser le navigateur à lire le dépôt (CORS)

**À faire une fois par bucket, et seulement pour le web.** Sans cela
l'enregistrement réussit et la relecture échoue : Chrome reçoit la réponse et
refuse de la laisser lire. Sur le téléphone la question ne se pose pas — il n'y
a pas de navigateur entre l'application et le dépôt.

Dans le **Cloud Shell** de la console Google Cloud (l'icône `>_`), projet
`grisbie-43ee9`, sans rien installer :

```bash
cat > cors.json <<'JSON'
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "responseHeader": ["Content-Type", "Content-Length", "Content-Range",
                       "Content-Encoding", "Content-Disposition",
                       "Cache-Control", "Authorization",
                       "x-goog-meta-firebaseStorageDownloadTokens"],
    "maxAgeSeconds": 3600
  }
]
JSON
gcloud storage buckets update gs://grisbie-43ee9.firebasestorage.app --cors-file=cors.json
gcloud storage buckets describe gs://grisbie-43ee9.firebasestorage.app --format="default(cors_config)"
```

**Pourquoi `*` et non `http://localhost:5000`** — une origine précise ne suffit
pas, et c'est le piège qui a coûté le plus de temps. Firebase ne sert pas les
fichiers lui-même : `firebasestorage.googleapis.com` **redirige** vers
`storage.googleapis.com`. Après une redirection d'origine croisée, le
navigateur exige l'autorisation sur la *nouvelle* adresse, avec une origine qui
n'est plus celle de départ. La politique restreinte ne correspond donc plus, et
seuls les fichiers non redirigés passent — d'où un `index.json` lisible et un
`characters.json` refusé, symptôme déroutant s'il en est.

**Ce que `*` n'ouvre pas** : aucun accès. Le CORS dit seulement à quelles pages
le navigateur autorise la lecture d'une réponse ; il faut déjà posséder
l'adresse exacte du fichier et son jeton. La règle du bucket, elle, ne bouge
pas et n'accorde l'écriture qu'à l'UID de l'auteur.

Après coup, recharger **en forçant** (Ctrl+Maj+R) : Chrome garde une heure le
résultat de ses vérifications précédentes.

`--dart-define-from-file` **est éprouvé** de son côté : un test jetable a
vérifié que les six valeurs arrivent bien par le fichier, et qu'elles manquent
sans lui.

## Construire pour le web

```bash
# Le jeu
flutter build web

# L'outil d'auteur
flutter build web -t lib/main_author.dart
```

**Exige** : rien de plus que le SDK Flutter — la chaîne dart2js est fournie
avec. **Ces deux commandes fonctionnent en session cloud**, et ce sont les
seules constructions qui y soient possibles.

**Produit** : `build/web/`, à servir par n'importe quel serveur statique. Les
saveurs Gradle ne s'appliquent pas ici : `--flavor` n'a pas de sens hors
Android, et c'est `-t` seul qui choisit entre le jeu et l'outil.

**À lancer après toute modification touchant à `dart:io`.** C'est le seul
contrôle qui attrape un import indisponible en navigateur : `flutter analyze`
et `flutter test` tournent sur la machine virtuelle Dart, où `dart:io` existe,
et ne le verraient pas.

`flutter build web` **réécrit `analysis_options.yaml`** pour y exclure `web/` —
c'est le comportement de l'outil, et le fichier suivi porte donc déjà cette
ligne.

## Vérifier

```bash
flutter analyze
flutter test
```

**Exige** : rien de plus que le SDK Flutter. Ces deux commandes ne passent pas
par Gradle, ignorent donc les saveurs, et **fonctionnent en session cloud**.

À lancer après toute modification de code. Elles prouvent le comportement du
moteur et la forme des fichiers de configuration ; elles ne prouvent pas que le
projet Android compile — seul un `flutter run` le dit.

Séparation moteur / interface, la règle structurante du projet :

```bash
grep -rn "package:flutter/" lib/domain lib/application && echo "VIOLATION" || echo "OK"
```

## Où va le contenu enregistré

Ce n'est pas une commande, mais c'est ce qu'on cherche juste après avoir appuyé
sur « Enregistrer » dans l'outil d'auteur.

| Plateforme | Destination |
|---|---|
| Appareil | `<documents de l'application>/content/`, l'arborescence de `assets/content/` |
| Navigateur | Le dossier de téléchargement, **un fichier à la fois**, nom aplati |

Les assets sont scellés au build : l'outil ne peut pas réécrire
`assets/content/`. Le dossier écrit se repose donc à la main dans le dépôt.

Dans un navigateur, un téléchargement ne crée pas de dossier :
`adventures/plage.json` descend sous le nom `adventures_plage.json`, à reposer
dans `adventures/`. C'est un dépannage, en attendant un dépôt distant.

## Ce que ce document ne couvre pas encore

Rien n'est écrit ici sur la construction d'un paquet publiable, la signature, ni
la mise en ligne : ces gestes n'ont jamais été faits. Ils seront ajoutés le jour
où ils auront abouti, pas avant. Ce qui reste à faire est dans `TODO.md`.
