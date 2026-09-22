# État courant

**Version : 0.27.0+43** — 22 septembre 2026

## Où en est le projet

**Le niveau test est jouable.** L'étape de départ s'affiche sur l'illustration
`Grisbie_plage2.jpg` : six mots en haut, trois zones translucides posées sur le
bus, la voiture et le sentier, glisser-déposer, aides et bouton de départ.
Chaque famille puise dans une liste pleine de sept mots, et un mot bien classé
est remplacé sur place par un mot de la réserve. La spécification est en version
de travail 0.8.

Le contenu vit désormais dans plusieurs fichiers reliés par un sommaire, décrits
par `docs/Format_fichier_aventure.md`. Les mots y sont regroupés en **listes
thématiques réutilisables**, qu'une famille cite au lieu de les porter. La boutique de la gare est un **tri
unique** : l'enfant y trie entre une liste et tout le reste, et une marchande y
pose la question — l'ornement, pas la mécanique.

**Un outil d'auteur existe**, sur un second point d'entrée `lib/main_author.dart`.
Il cale les zones de dépôt au doigt sur l'étape réelle et produit leur JSON. Le
jeu livré n'en contient aucune trace.

**Les deux saveurs se construisent et se lancent** depuis le poste de
développement — les builds restent impossibles en session cloud. **Le rendu réel
a été jugé sur appareil et convient** : position des zones, taille des
étiquettes, lisibilité sur le décor. C'était la première fois que le jeu était
vu à l'écran ; jusque-là, seul son comportement était prouvé, par 158 tests.

## Chantier en cours

**Un outil qui crée une journée entière**, au lieu de recopier des coordonnées :
charger une image, saisir les textes, enregistrer la mise en place et
l'articulation entre les lieux. Il tournera sur le téléphone et enregistrera par
Firebase Storage — voir les décisions ci-dessous.

Découpage en six étapes, les deux premières faites, la troisième entamée :

1. ✅ **L'écriture et sa fidélité** — `ContentSink`, `ContentWriter`, et la preuve
   par test qu'aucun champ ne disparaît à l'enregistrement.
2. ✅ **L'écriture sur un vrai disque** — `FileContentSink`, `FileContentSource`,
   et l'aller-retour complet jusqu'au chargement par le jeu.
3. ✅ **Textes et structure** — `validate()` classe chaque anomalie en *faux* ou
   *incomplet* (0.10.0), `loadDraft` ouvre une aventure inachevée, le lettrage du
   croquis est calculé (0.12.0), et **l'écran de construction marche** (0.14.0) :
   bouton « Ajouter », nombre de trajets, nature, nom, et chaque arrivée devient
   une carte prolongeable en dessous. Une aventure se crée aussi à partir de
   rien, **les récits se saisissent** depuis 0.19.0, avec le nom du lieu et son
   illustration, et **l'enregistrement existe** depuis 0.22.0 — sur l'appareil
   comme par le téléchargement d'un navigateur. Depuis 0.24.0, **l'outil relit
   ce qu'il a écrit** : l'accueil liste les aventures du dossier de travail,
   contenu livré en repli, et les rouvre inachevées.
4. 🟡 **L'image** — **la choisir et l'afficher sont faits, partout** :
   `contentImageProvider` lit le bundle, le réseau ou le disque selon le
   chemin, et depuis 0.26.0 le bouton existe aussi dans un navigateur.
   **Restent deux manques** : l'image **ne voyage pas** — `ContentSaver`
   n'écrit que du JSON, donc rien ne passe du poste au téléphone ni l'inverse,
   et dans un navigateur elle meurt avec l'onglet — et il faut toujours la
   **rapatrier** à la main dans `assets/pictures/`. À éprouver aussi sur un
   téléphone : aucun greffon ne tourne en session cloud.
5. ⬜ **Le lexique et les listes** — saisir mots et découpages, unicité garantie,
   et composer les listes thématiques. Le modèle est posé depuis 0.17.0
   (`WordList`, `ContentWriter.writeWordLists`) ; reste l'écran.
6. 🟡 **Rebrancher le calage** — **fait** : il s'ouvre depuis l'éditeur de
   lieu, sur l'étape en cours d'édition, et rend l'étape calée.
   **Enregistrer au lieu de copier** reste le manque, commun avec l'étape 3.

**Ce qui bloque Firebase** : le code est là depuis 0.23.0, mais le projet
le projet `grisbie-43ee9` vient d'être créé, mais Storage n'y est pas activé et
rien n'a jamais été exécuté. Les préalables sont
listés dans `TODO.md`, ils relèvent de la console Firebase et de l'appareil.
Le dépôt, lui, est prêt à le recevoir : les noms sont fixés depuis 0.9.3, et
depuis 0.9.4 **deux saveurs Android séparent le jeu de l'outil d'auteur**, avec
un seul emplacement autorisé pour `google-services.json`
(`Noms_et_identifiants.md`). **Les deux saveurs se construisent et se lancent**
sur le poste depuis 0.9.5 : le montage tient. Ne manque plus que ce qui relève
de la console.

Deux sujets antérieurs restent ouverts, sans être le chantier : la gare et la
boutique n'ont ni décor ni zones placées, et le **tirage libre** peut ne proposer
aucun mot d'une famille donnée — question que 0.17.0 rend plus pressante, le
tirage se faisant désormais à deux étages.

**Les listes livrées font encore exactement la taille de la partie.** Le
dispositif de 0.17.0 est en place et éprouvé, mais il ne rapportera rien tant
qu'aucune liste n'aura plus de mots qu'il n'en faut : écrire du vocabulaire est
un travail d'auteur, pas de code.

## Dernières modifications

### 0.27.0+43 — Une panne n'est pas une absence
- **L'aventure était bien déposée, mais n'apparaissait pas.** Le repli de
  0.24.0 attrapait *tout* : un refus, une coupure, un blocage du navigateur
  servaient silencieusement le contenu livré.
- `ContentFileNotFound` nomme l'**absence**, et le repli ne vaut plus que pour
  elle. `RemoteContentStore` ne traduit que `object-not-found`.
- **Second piège corrigé** : quitter le parcours jetait tout le travail non
  enregistré, sans un mot. Une question le retient désormais, `PopScope`
  compris — le geste de retour du système passe par là aussi.
- « Enregistrer et quitter » ne sort **que si l'écriture a réussi**.
- **Cause première non réparée** : la lecture depuis un navigateur est soumise
  au CORS du bucket, qu'un projet neuf n'a pas. Console Google Cloud, voir
  `TODO.md`.
- 381 tests au vert, dont 9 nouveaux.

### 0.26.0+42 — Charger une image depuis un navigateur
- **Le bouton existe enfin sur le web.** `image_picker_for_web` était déjà dans
  le graphe, et `contentImageProvider` savait déjà afficher une adresse
  `blob:` : seule la recopie ne passait pas, et elle n'a pas d'objet là.
- `picture_keeper_io.dart` / `_web.dart`, choisis à la compilation.
- **`PictureLibrary.keepsPictures`** : l'écran annonce que l'image choisie dans
  un navigateur disparaîtra en fermant l'onglet. Le calage, lui, survit.
- La différence est dans l'interface, **pas dans un `kIsWeb`** consulté par un
  widget — sans quoi elle ne s'éprouverait pas.
- **L'image ne voyage toujours pas** : `ContentSaver` n'écrit que du JSON.
- 372 tests au vert ; les deux points d'entrée compilent pour le web.

### 0.25.0+41 — Un trajet et son lieu portent deux noms
- **L'outil enseignait une règle fausse** : un seul nom, et le lieu d'arrivée
  baptisé d'après le trajet. « En bus » menait à un lieu appelé « En bus ».
- Ouvrant l'aventure livrée, où « En bus » mène à « La gare », l'auteur a cru
  à un affichage cassé. **Et l'outil ne savait pas écrire ce contenu-là.**
- `NewTrip` porte `name` **et** `locationName` ; `AddTripsPage` demande les
  deux, le second proposé d'après le premier et détaché dès qu'on l'écrit.
- **L'identifiant du lieu vient du lieu** : « La gare » donne `gare`, comme le
  contenu livré.
- Un trajet dit où il mène : « En bus → La gare ». Tu quand il se répète.
- 371 tests au vert, dont 15 nouveaux.

### 0.24.0+40 — L'outil relit ce qu'il a écrit
- **La boucle est fermée** : l'accueil lisait toujours les assets, scellés au
  build. On pouvait enregistrer une aventure et ne jamais la rouvrir.
- `FallbackContentSource` : le travail devant, le contenu livré derrière. Le
  repli vaut pour l'absence, **jamais pour un fichier écrit illisible**.
- **Défaut invisible corrigé** : `ContentSaver` recopiait les *autres*
  aventures depuis les assets — enregistrer la gare ramenait la plage à sa
  version d'origine. Il lit maintenant par où il écrit.
- L'accueil reçoit une **fabrique** de dépôt : le dépôt met le sommaire en
  cache, et se connecter change la source.
- `DeviceContentSink` → `DeviceContentFolder`, les deux bouts au même endroit.
- 356 tests au vert, dont 10 nouveaux ; les deux points d'entrée compilent pour
  le web.

### 0.23.1+39 — Un seul projet Firebase, et il existe
- **`grisbie-43ee9` est créé.** Firebase suffixe les identifiants ; définitif.
- **Un seul projet, pas de dev/prod** : ni utilisateurs ni données à protéger
  d'un environnement de test, et la décision se renverse en changeant une ligne
  de commande.
- La section Firebase de `Noms_et_identifiants.md` **était devenue fausse** —
  elle décrivait le montage par `google-services.json` supprimé en 0.23.0.
  Réécrite.
- **Attendu au prochain pas** : Cloud Storage réclamera sans doute le plan
  Blaze, un projet neuf ne provisionnant plus de bucket sur Spark.
- Aucun changement de code.

### 0.23.0+38 — Le dépôt distant
- **L'outil dépose le contenu sur Firebase Storage et le relit.** C'est le pont
  entre le poste et le téléphone.
- **Pas de `google-services.json`** : le greffon Gradle qui le produit échoue
  quand il manque, et aurait cassé la saveur `jeu`. Des options explicites, par
  `--dart-define`. Conséquence : **l'auto-initialisation d'Android n'existe
  plus du tout**, et un test l'exige.
- **Connexion par e-mail**, pas par Google : Google sur Android suppose des
  empreintes SHA-1 qui marchent en debug et cassent en release.
- `RemoteContentStore` est un `ContentSource` **et** un `ContentSink` :
  `ContentSaver` et `ContentRepository` n'ont pas bougé d'une ligne.
- **Rien n'a été exécuté** : le projet Firebase n'existe pas encore. Marche à
  suivre réécrite dans `TODO.md`.
- 346 tests au vert, dont 14 nouveaux.


## Décisions prises

- **Plateformes** : Web, Android, Windows. iOS et macOS ne sont pas visés, et `ios/`
  a été supprimé du dépôt en 0.1.1. `android/` et `web/` sont configurés.
- **Le web sert d'abord l'outil d'auteur** : écrire sur un poste, illustrer sur
  le téléphone. Le jeu compile aussi pour le web, mais ce n'est pas ce qui a
  motivé la cible.
- **Deux dépendances tierces, pour l'outil d'auteur seulement** :
  `image_picker` et `path_provider`, de l'équipe Flutter. Embarquées dans le
  jeu faute d'un `pubspec.yaml` par saveur, jamais appelées par lui, et un test
  l'exige. `image_picker` passe par le Photo Picker d'Android 13+, qui ne
  demande aucune permission.
- **Pas de serveur dans le jeu** : la progression reste sur l'appareil. Le public
  étant mineur, aucune donnée personnelle ne sort de la machine.
- **Firebase ne s'initialise jamais tout seul** : des `FirebaseOptions`
  explicites passées au lancement, pas de `google-services.json`. Le jeu ne
  peut pas contacter Firebase même par mégarde, puisque rien ne l'initialise —
  garantie plus forte que celle que les saveurs donnaient.
- **Connexion de l'auteur par e-mail et mot de passe** : Google sur Android
  exige des empreintes SHA-1 par magasin de clés, qui cassent en release.
- **Firebase Storage, en tuyau d'auteur seulement** — et **Storage, pas
  Firestore** : l'outil de création y dépose le contenu, on le relit depuis le
  poste, et il finit commité dans `assets/content/` comme aujourd'hui. **Le jeu
  livré ne contacte rien.** Le cycle voulu, dit par l'auteur : *construire une
  aventure depuis le téléphone ou l'ordinateur, l'enregistrer sur Storage, puis
  la télécharger pour l'inclure au dépôt.* Storage est un **transit entre deux
  de ses appareils**, jamais une source que l'enfant interrogerait — ce qui
  vaut aussi pour les illustrations, une fois qu'elles y passeront. Le choix répond au fait qu'un fichier écrit sur un
  téléphone est difficile à rapatrier. **Un seul projet**, `grisbie-43ee9`, où
  l'application Android est enregistrée sous `fr.naryabordeaux.grisbie.auteur` —
  **jamais sous l'identifiant du jeu**, qui n'existe ainsi dans aucun projet
  Firebase. Pas de dev/prod : il n'y a ni utilisateurs ni données à protéger
  d'un environnement de test, et la décision se renverse en changeant une ligne
  de commande.
- **Un compte unique pour le bucket**, celui de l'auteur. L'usage est
  solo : personne d'autre n'a de contenu à déposer, et un bucket ouvert en
  écriture serait trouvé sans avoir à être connu. La règle nomme un UID, jamais
  une adresse e-mail — le dépôt part en open source. Marche à suivre dans
  `TODO.md`.
- **« Mission » et « aventure » désignent la même chose** : une journée de
  Grisbie, avec ses étapes. Le contenu et le code ne connaissent qu'`Adventure`,
  et c'est le seul mot à employer.
- **Le jeu s'appelle Grisbie**, et l'identifiant Android
  `fr.naryabordeaux.grisbie` est **définitif dès la première publication** sur le
  Play Store. Table de vérité dans `Noms_et_identifiants.md`, contrôlée par test.
- **Le contenu est écrit en français, identifiants compris**, et **un mot est
  désigné par son orthographe** : `Word` n'a pas de clé technique. Deux mots de
  même orthographe deviennent impossibles, ce qu'ils étaient déjà en pratique.
- **Le découpage syllabique suit les sons, pas les lettres** : `["a", "rê"]` pour
  « arrêt ». Il n'a donc pas à reconstituer l'orthographe, et **aucun test ne doit
  l'exiger** — un tel contrôle interdirait les découpages recherchés.
- **Contenu pédagogique séparé du code** : les mots, familles et niveaux vivent dans
  `assets/content/` en JSON.
- **Le classement est libre, le départ est choisi** : compléter une famille ouvre sa
  destination sans y envoyer l'enfant. Plusieurs destinations peuvent être ouvertes
  en même temps ; l'enfant part quand il le décide.
- **Une seule aide** : le découpage syllabique, dès la 1ʳᵉ erreur sur le mot.
  L'illustration a été écartée — avec trois familles, les possibilités se
  réduisent d'elles-mêmes à mesure que les catégories se remplissent.
- **Listes pleines** : une famille s'ouvre quand tous ses mots sont classés.
  Remplir une catégorie est en soi une aide pour les mots suivants.
- **Étapes imbriquées** : une destination atteinte ouvre une étape de même nature,
  avec ses propres familles. Le modèle est récursif, un seul moteur sert partout.
- **Un lieu raconte son arrivée, jamais son départ** : la narration appartient
  à celui qui accueille. Un récit de départ a existé, et disait la même chose
  deux fois.
- **Contenu en plusieurs fichiers** : un sommaire, des lexiques par domaine, les
  personnages, les aventures. Un mot n'est défini qu'une fois.
- **Leurres écrits à la main** : jamais ramassés automatiquement, sous peine de
  sortir un mot appartenant vraiment au thème et de refuser une bonne réponse.
- **Listes réutilisables, plus grandes que la partie** : le moteur en tire
  quelques mots à l'entrée du lieu, après avoir retiré ceux qui sont communs à
  plusieurs listes du même lieu. Le mot ambigu n'est plus interdit à l'auteur,
  il est retiré par la machine — et rejouer donne d'autres mots.

## Points ouverts

Les questions fonctionnelles non tranchées sont listées en fin de
`Specification_jeu_decouverte_lecture.md` et ne sont pas reprises ici.
