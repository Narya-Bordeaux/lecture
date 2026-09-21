# État courant

**Version : 0.9.2+18** — 21 septembre 2026

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

Le rendu visuel n'a jamais été vu : les builds sont impossibles en session cloud.
Seul le comportement est prouvé, par 119 tests.

## Chantier en cours

**Niveau test « Grisbie va à la plage »** — reste à juger le rendu réel sur
appareil, puis à traiter la suite du parcours : la gare n'a pas de décor et ses
zones n'ont pas de position, l'étape s'y affiche donc sur fond uni.

Un réglage attend un avis : le **tirage libre**, qui peut ne proposer aucun mot
d'une famille donnée. Les six thèmes proposés (station-service, garage, marché,
école, loueur de vélos, forêt) restent à écrire.

## Dernières modifications

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

### 0.9.0+16 — Outil de calage des zones, et un démarrage cassé
- **`lib/main.dart` demandait encore `grisbie_beach`** après le renommage de
  0.8.0 : le jeu n'aurait pas démarré sur l'appareil, avec 119 tests au vert.
  Corrigé, et `test/infrastructure/startup_test.dart` monte désormais la garde.
- **Mode auteur** — `lib/main_author.dart`, second point d'entrée : l'étape
  réelle en aperçu inerte, des poignées pour déplacer et redimensionner les
  zones au doigt, le JSON copié dans le presse-papiers. Le jeu livré n'en
  contient aucune trace.
- `AreaEditor` (Dart pur) porte toute la géométrie : bords, taille minimale de
  48 points, arrondi au centième, chevauchement jugé sur les valeurs arrondies.
- Une étape sans zone posée en reçoit par défaut, réparties et disjointes.
- `BackgroundImageSize` extrait : la scène de jeu et l'outil partagent une
  seule résolution d'image, sans quoi le calage porterait sur une autre
  géométrie que le jeu.
- Mesure consignée : la bande haute mangée par le bandeau vaut 14,3 % sur
  tablette, 11 % sur petit téléphone, rien sur téléphone allongé. D'où la
  règle `top` ≥ 0,15.
- 140 tests au vert.

### 0.8.0+15 — Contenu entièrement en français, le mot est sa propre clé
- `Word` n'a plus d'identifiant : son `text` le désigne partout. Une aventure
  cite `"arrêt"`, plus `"bus_stop"`. La rustine `garage_word` disparaît.
- Les identifiants d'étapes, de familles et de personnages passent en français
  (`maison`, `en_bus`, `marchande`). Seuls les noms de champs JSON restent
  anglais, puisqu'ils portent directement les champs Dart.
- Le doublon détecté au chargement est désormais celui de l'orthographe :
  deux entrées « arrêt » sont refusées, et le message nomme le mot.
- Le découpage suit les sons et non les lettres. Le test qui exigeait qu'il
  reconstitue l'orthographe est retiré : il interdisait `["a", "rê"]`.
- Fichiers renommés : `grisbie_plage.json`, `lexicon/nourriture.json`,
  `lexicon/lieux.json`.
- 119 tests au vert.

### 0.7.1+14 — Plus d'écran de texte redondant au départ
- Le lieu de départ n'a plus de récit d'arrivée : il répétait la page de garde,
  et faisait enchaîner deux écrans de texte avant de jouer.
- Après « C'est parti ! », le jeu commence directement.
- Un test vérifie que le lieu de départ ne redit pas la page de garde.

### 0.7.0+13 — Page de garde d'une aventure
- `Adventure.opening` : un titre, une illustration horizontale et un texte,
  montrés une fois avant le premier lieu.
- Mise en page propre : le titre annonce, l'image occupe la largeur à ses
  proportions, le texte se lit dessous, le bouton reste hors du défilement.
- « Recommencer » repasse par la page de garde.
- 118 tests au vert.

### 0.6.3+12 — Intitulés au-dessus des zones, marge système en bas
- L'intitulé d'une zone est posé **au-dessus** du cadre, libre de déborder
  latéralement : « En voiture » s'abrégeait en « En voitu… ».
- Le cadre est ainsi entièrement disponible pour les mots déposés.
- L'illustration se cale au-dessus de la barre de navigation Android.
- 108 tests au vert, dont un qui échoue si un intitulé peut être tronqué.

### 0.6.2+11 — L'illustration et les zones débordaient de l'écran
- L'illustration était recadrée pour remplir l'écran. Sur un 1080 × 2340, elle
  devait mesurer 1560 px de large : 480 px sortaient, et les zones ancrées au
  décor sortaient avec elles.
- Elle est désormais montrée **en entier**, calée en bas, la bande du haut étant
  comblée par `backgroundColor` — le bleu du ciel de l'image, invisible au
  raccord.
- `computeSceneRect` extraite en fonction pure, éprouvée sur quatre appareils
  réels par `test/ui/scene_geometry_test.dart`.
- 102 tests au vert.

### 0.6.1+10 — Assets manquants : le jeu ne s'ouvrait plus
- `pubspec.yaml` ne déclarait que `assets/content/adventures/`. Flutter
  n'embarque pas les sous-dossiers : `index.json`, `characters.json` et les
  trois lexiques n'étaient pas dans l'application, et le chargement échouait.
- Les quatre répertoires sont déclarés.
- `test/infrastructure/declared_assets_test.dart` compare les fichiers réels aux
  déclarations du pubspec — le seul test qui regarde ce qui sera livré.
- L'écran d'erreur montre le diagnostic en mode développement, au lieu de le
  cacher derrière « Le jeu n'a pas pu s'ouvrir ».

### 0.6.0+9 — Format de contenu en plusieurs fichiers
- `index.json` (le sommaire), `lexicon/*.json` (le vocabulaire, chaque mot défini
  une seule fois), `characters.json`, `adventures/*.json`.
- Récit à deux temps par lieu : `onArrival` avant de jouer, `onCompletion` au
  départ, affichés sur un écran dédié.
- Rencontres : un `character` dans un lieu, et un classeur **sans destination**
  pour le rebut d'une énigme.
- Les mots sont portés par les familles ; `Stage.words` en est dérivé.
- `docs/Format_fichier_aventure.md` : la spécification du format, pour qui écrit
  du contenu sans toucher au code.
- 78 tests au vert.

### 0.5.0+8 — Listes pleines, une seule aide
- Les listes sont pleines : une famille s'ouvre quand tous ses mots sont classés.
  `goal` disparaît du contenu. Remplir une catégorie devient une aide en soi,
  puisque les mots restants ne peuvent plus lui appartenir.
- L'aide « illustration » est retirée : `Hint.illustration`,
  `HintPolicy.illustrationThreshold` et `Word.illustrationAsset` supprimés.
- Le découpage syllabique reste l'unique aide, dès la 1ʳᵉ erreur.

### 0.4.1+7 — Listes de sept mots, sans ambiguïté
- Onze mots retirés, partagés entre deux familles : navette, car, voyageur pour
  le bus ; ceinture, pneu, parking, capot, phare pour la voiture ; trottoir,
  semelle, lacet pour la marche.
- `radio` et `clé` ajoutés à « En voiture », qui manquait de vocabulaire propre.
- Trois listes de sept mots, objectif abaissé de 5 à 4.
- Spécification : une section sur le champ lexical des familles, qui doivent
  être disjointes — contrainte plus forte qu'il n'y paraît.

### 0.4.0+6 — Réserve de dix mots par famille
- Trois listes de dix mots ; six sont proposés à la fois, les autres attendent.
- Un mot bien classé est remplacé **sur place** par un mot de la réserve ; les
  autres mots ne bougent pas. Un mot mal classé ne déclenche rien.
- Objectif réglable par famille (`goal`), fixé à 5 : sans lui, il faudrait près
  de trente classements pour ouvrir un chemin.
- La zone affiche l'avancement vers l'objectif (« 3 / 5 »), pas vers la réserve.
- 65 tests au vert.

### 0.3.0+5 — Interface du niveau test
- Décor plein écran, six étiquettes en grille 2 × 3, trois zones translucides
  ancrées sur le bus, la voiture et le sentier.
- Glisser-déposer : le mot juste se range dans sa zone, le mot faux revient à sa
  case en tremblant et débloque son découpage syllabique.
- Bouton « Partir » en bas, une fois une famille complète.
- Contenu revu : famille « En bus » au lieu de « En train », mots choisis pour
  qu'aucun ne se devine par le nom de sa famille.
- 50 tests, dont l'étape réelle montée sur trois formats d'écran.

### 0.2.0+4 — Moteur d'étape et niveau test
- Domaine : `Word`, `WordFamily`, `Stage`, `Adventure`, `HintPolicy`, `Hint`.
- Moteur `StageEngine` : placement, refus immédiat, comptage des erreurs par mot,
  déblocage des aides, complétion d'une famille, ouverture des destinations,
  départ à l'initiative de l'enfant.
- Contenu `assets/content/adventures/grisbie_beach.json` : trois chemins au départ,
  une étape imbriquée dans la gare, la plage en arrivée.
- 31 tests au vert, `flutter analyze` sans erreur.
- Spécification mise à jour (v0.5) d'après les décisions prises en session.

### 0.1.2+3 — Flutter disponible dans l'environnement cloud
- Hook de démarrage de session installant le SDK Flutter 3.47.5, version épinglée et
  archive vérifiée. `flutter analyze` et `flutter test` sont désormais exécutables en
  session cloud ; les builds ne le sont toujours pas.
- Démarrage à froid 1 min 34 s, reprise à chaud 0,9 s.

### 0.1.1+2 — Retrait de la plateforme iOS
- Suppression du dossier `ios/`, entièrement généré et jamais personnalisé, pour une
  plateforme non visée. Commande de régénération consignée dans `docs/TODO.md`.
- `.metadata` mis en cohérence : entrée de migration `ios` retirée.

### 0.1.0+1 — Mise en place du cadre de travail
- Durcissement du `.gitignore` en vue d'une publication open source : `.vscode/`,
  `.env` et variantes (avec exception `.env.example`), `.claude/settings.local.json`.
- Ajout de `CLAUDE.md` : conventions du projet et règle de séparation moteur /
  interface.
- Ajout de `docs/current.md`, `docs/versions.md` et `docs/TODO.md`.
- Passage de la version générée par défaut (1.0.0+1) à 0.1.0+1, le projet n'ayant
  pas encore de code applicatif.

## Décisions prises

- **Plateformes** : Web, Android, Windows. iOS et macOS ne sont pas visés, et `ios/`
  a été supprimé du dépôt en 0.1.1. Seul `android/` est configuré à ce jour.
- **Pas de serveur** : la progression reste sur l'appareil. Le public étant mineur,
  aucune donnée personnelle ne sort de la machine. Un backend n'est pas exclu à
  terme, mais ce serait une décision à part entière.
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
