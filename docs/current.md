# État courant

**Version : 0.9.3+19** — 21 septembre 2026

## Où en est le projet

**Le niveau test est jouable.** L'étape de départ s'affiche sur l'illustration
`Grisbie_plage2.jpg` : six mots en haut, trois zones translucides posées sur le
bus, la voiture et le sentier, glisser-déposer, aides et bouton de départ.
Chaque famille puise dans une liste pleine de sept mots, et un mot bien classé
est remplacé sur place par un mot de la réserve. La spécification est en version
de travail 0.8.

Le contenu vit désormais dans plusieurs fichiers reliés par un sommaire, décrits
par `docs/Format_fichier_aventure.md`. Une rencontre avec un personnage existe,
dans la boutique de la gare.

**Un outil d'auteur existe**, sur un second point d'entrée `lib/main_author.dart`.
Il cale les zones de dépôt au doigt sur l'étape réelle et produit leur JSON. Le
jeu livré n'en contient aucune trace.

Le rendu visuel n'a jamais été vu : les builds sont impossibles en session cloud.
Seul le comportement est prouvé, par 150 tests.

## Chantier en cours

**Un outil qui crée une journée entière**, au lieu de recopier des coordonnées :
charger une image, saisir les textes, enregistrer la mise en place et
l'articulation entre les lieux. Il tournera sur le téléphone et enregistrera par
Firebase Storage — voir les décisions ci-dessous.

Découpage en six étapes, les deux premières faites :

1. ✅ **L'écriture et sa fidélité** — `ContentSink`, `ContentWriter`, et la preuve
   par test qu'aucun champ ne disparaît à l'enregistrement.
2. ✅ **L'écriture sur un vrai disque** — `FileContentSink`, `FileContentSource`,
   et l'aller-retour complet jusqu'au chargement par le jeu.
3. ⬜ **Textes et structure** — créer des lieux, leurs récits, leurs familles,
   leurs destinations, avec les erreurs signalées en direct. **Entièrement
   faisable en session cloud, et ne dépend pas de Firebase** : c'est la suite
   naturelle.
4. ⬜ **L'image** — la choisir, la copier, l'afficher. Pendant l'édition il
   faudra la charger **par chemin de fichier** : une image fraîchement ajoutée
   n'est pas dans le bundle, les assets étant scellés au build.
5. ⬜ **Le lexique** — saisir mots et découpages, unicité garantie.
6. ⬜ **Rebrancher le calage** sur l'aventure éditée, et enregistrer au lieu de
   copier.

**Ce qui bloque Firebase** : rien n'est encore dans le dépôt, et l'intégration
n'est pas testable en session cloud faute de SDK Android. Les préalables sont
listés dans `TODO.md`, ils relèvent de la console Firebase et de l'appareil.
Les noms, eux, sont fixés depuis 0.9.3 — `Noms_et_identifiants.md`. Le premier
geste côté dépôt sera de **séparer le jeu de l'outil d'auteur par des saveurs
Gradle** : sans elles, un `google-services.json` déposé dans `android/` partirait
dans le jeu des enfants, et un test l'interdit donc pour l'instant.

Deux sujets antérieurs restent ouverts, sans être le chantier : la gare et la
boutique n'ont ni décor ni zones placées, et le **tirage libre** peut ne proposer
aucun mot d'une famille donnée.

## Dernières modifications

### 0.9.3+19 — Le jeu prend son nom
- **Grisbie partout** : package Dart `grisbie`, `applicationId` Android
  `fr.naryabordeaux.grisbie`, libellé « Grisbie » sous l'icône, titre
  « Les Aventures de Grisbie ». Le manifeste affichait encore `reading_game`.
- L'`applicationId` devient **définitif à la première publication** : c'était le
  moment ou jamais.
- `docs/Noms_et_identifiants.md` fixe la table de vérité, et
  `test/infrastructure/android_packaging_test.dart` la contrôle — rien d'autre
  ne regardait ces valeurs, aucun build Android n'étant possible ici.
- Signature de release câblée par `android/key.properties` (modèle commenté
  fourni, clé jamais versionnée). Fichier absent, le build retombe sur la clé de
  debug.
- **Aucun `google-services.json` toléré dans `android/`**, vérifié par test : le
  SDK Firebase s'initialise seul dès qu'il est présent, et les deux points
  d'entrée partagent le dossier Android.
- Firebase : le produit retenu est **Cloud Storage**, pas Firestore. Projets
  `narya-grisbie-dev` et `narya-grisbie-prod`.
- L'historique ancien de ce fichier est retiré, conformément à la règle des deux
  ou trois dernières versions ; il reste entier dans `versions.md`.
- 155 tests au vert.

### 0.9.2+18 — Écrire sur un vrai disque, et le relire avec le jeu
- `FileContentSink` écrit le contenu dans un dossier, en créant les répertoires
  manquants : un dossier vierge n'a ni `adventures/` ni `lexicon/`.
- `FileContentSource` le relit — les assets étant scellés au build, l'outil ne
  peut pas relire par eux ce qu'il vient d'enregistrer.
- **Test de bout en bout** : écrire l'aventure dans un dossier temporaire, la
  recharger avec `ContentRepository`, et retrouver les mêmes étapes et les
  mêmes zones. Les tests précédents travaillaient en mémoire et ne voyaient
  ni les chemins ni les dossiers absents.
- `ContentWriter.writeIndex` : une aventure que le sommaire n'annonce pas est
  introuvable pour le jeu.
- Le `DiskContentSource` des tests s'appuie désormais sur `FileContentSource`,
  au lieu d'en être une seconde version.
- 150 tests au vert.

### 0.9.1+17 — Écrire le contenu, et prouver que rien ne se perd
- `ContentSink`, symétrique de `ContentSource`, et `ContentWriter` qui réécrit
  une aventure au format exact que le chargement relit — via les `toJson()`
  existants, pour qu'il n'y ait pas deux descriptions du format.
- **Le test qui compte** : chaque champ du fichier livré doit se retrouver dans
  le fichier écrit, et un champ manquant est nommé par son chemin
  (`/stages[0]/backgroundColor`). Vérifié en supprimant un champ pour de bon.
- Réécrire deux fois donne le même fichier : ouvrir puis fermer l'outil sans
  rien changer ne produira pas de différence dans git.
- JSON indenté et terminé par un saut de ligne : le contenu reste relisible.
- Rien ne l'utilise encore — c'est le socle de l'outil de création.
- 144 tests au vert.

## Décisions prises

- **Plateformes** : Web, Android, Windows. iOS et macOS ne sont pas visés, et `ios/`
  a été supprimé du dépôt en 0.1.1. Seul `android/` est configuré à ce jour.
- **Pas de serveur dans le jeu** : la progression reste sur l'appareil. Le public
  étant mineur, aucune donnée personnelle ne sort de la machine.
- **Firebase Storage, en tuyau d'auteur seulement** — et **Storage, pas
  Firestore** : l'outil de création y dépose le contenu, on le relit depuis le
  poste, et il finit commité dans `assets/content/` comme aujourd'hui. **Le jeu
  livré ne contacte rien.** Le choix répond au fait qu'un fichier écrit sur un
  téléphone est difficile à rapatrier. Deux projets, `narya-grisbie-dev` et
  `narya-grisbie-prod`, où l'application Android est enregistrée sous
  `fr.naryabordeaux.grisbie`.
  Précaution qui va avec : les deux points d'entrée partagent `pubspec.yaml`, et
  sur Android le SDK Firebase s'initialise seul dès que `google-services.json`
  est présent — ce fichier ne doit donc exister que dans la saveur « auteur ».
  Tant que cette saveur n'existe pas, un test l'interdit partout.
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
- **Contenu en plusieurs fichiers** : un sommaire, des lexiques par domaine, les
  personnages, les aventures. Un mot n'est défini qu'une fois.
- **Leurres écrits à la main** : jamais tirés au hasard, sous peine de sortir un
  mot appartenant vraiment au thème et de refuser une bonne réponse.

## Points ouverts

Les questions fonctionnelles non tranchées sont listées en fin de
`Specification_jeu_decouverte_lecture.md` et ne sont pas reprises ici.
