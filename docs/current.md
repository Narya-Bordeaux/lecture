# État courant

**Version : 0.9.6+22** — 21 septembre 2026

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
Le dépôt, lui, est prêt à le recevoir : les noms sont fixés depuis 0.9.3, et
depuis 0.9.4 **deux saveurs Android séparent le jeu de l'outil d'auteur**, avec
un seul emplacement autorisé pour `google-services.json`
(`Noms_et_identifiants.md`). **Les deux saveurs se construisent et se lancent**
sur le poste depuis 0.9.5 : le montage tient. Ne manque plus que ce qui relève
de la console.

Deux sujets antérieurs restent ouverts, sans être le chantier : la gare et la
boutique n'ont ni décor ni zones placées, et le **tirage libre** peut ne proposer
aucun mot d'une famille donnée.

## Dernières modifications

### 0.9.6+22 — Les commandes ont un document
- **Les deux saveurs se construisent et se lancent sur le poste.** Le montage
  Android tient.
- `docs/Commandes.md` : ce que l'on tape pour lancer et vérifier, avec pour
  chaque commande ce qu'elle exige et ce qu'elle produit. **Une commande n'y
  entre que le jour où elle a réellement été exécutée** — rien sur la
  construction d'un paquet publiable ni sur la signature.
- Dégroupage : trois endroits portaient leur propre copie des deux commandes de
  lancement — la section « Construire » de `Noms_et_identifiants.md`, le README
  de `src/auteur/` et un commentaire de `build.gradle.kts`. Tous renvoient
  désormais au document, seul à les décrire.
- 158 tests au vert, inchangés : rien de fonctionnel n'a bougé.

### 0.9.5+21 — Les saveurs configurent enfin
- Le premier vrai build s'arrêtait avant de compiler : « Product Flavor jeu
  contains custom resource values, but the feature is disabled ». **AGP 9
  désactive `resValue()` par défaut**, et les libellés sous l'icône s'écrivaient
  ainsi.
- Ils deviennent de vraies ressources, `src/jeu/res/values/strings.xml` et
  `src/auteur/res/values/strings.xml`. Plutôt que de rallumer un drapeau que les
  versions suivantes d'AGP éteindront encore : le recouvrement par saveur est le
  mécanisme le plus stable d'Android, et un libellé **est** une ressource.
- Le test lit ces deux fichiers et **refuse tout `resValue(`** dans le build.
- Rappel de la limite annoncée en 0.9.4 : le test avait bien vérifié que les
  libellés existaient, pas que Gradle accepterait la façon de les produire. Un
  test qui lit des fichiers ne remplace pas un build.
- 158 tests au vert.

### 0.9.4+20 — Deux saveurs Android, deux paquets
- **`jeu` et `auteur`**, dans la dimension `usage`. La saveur auteur porte le
  suffixe `.auteur` : les deux applications cohabitent sur le téléphone, et un
  jeu construit par erreur avec elle ne porte pas l'identifiant publié — il est
  donc impubliable, et l'erreur reste sans conséquence.
- `google-services.json` a désormais **un emplacement légitime**,
  `android/app/src/auteur/`, et un seul. Le test le refuse ailleurs. Il est
  maintenant ignoré par git partout : le dépôt est destiné à l'open source, et
  le test lit le disque, pas l'index — un fichier ignoré mais présent échoue
  tout autant.
- L'application Firebase est à enregistrer sous
  `fr.naryabordeaux.grisbie.auteur`, **pas** sous l'identifiant du jeu.
- Le libellé sous l'icône passe du manifeste aux saveurs (`@string/app_name`) :
  « Grisbie » et « Grisbie auteur », sans quoi les deux icônes seraient
  indiscernables.
- **Une saveur ne choisit pas le point d'entrée Dart.** `main_author.dart`
  vérifie `appFlavor` au démarrage et refuse la saveur du jeu ; le suffixe
  couvre l'autre sens. `--flavor` devient obligatoire pour tout build.
- **Non vérifié ici** : le test lit des fichiers, il ne lance pas Gradle. Il
  attrape un nom qui dérive ou un fichier égaré, il ne prouve pas que le projet
  Android compile. Premier vrai build à faire sur le poste.
- 158 tests au vert.

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
  `fr.naryabordeaux.grisbie.auteur` — **jamais sous l'identifiant du jeu**, qui
  n'existe ainsi dans aucun projet Firebase.
  Précaution qui va avec : les deux points d'entrée partagent `pubspec.yaml`, et
  sur Android le SDK Firebase s'initialise seul dès que `google-services.json`
  est présent. D'où les deux saveurs `jeu` et `auteur`, et l'unique emplacement
  autorisé pour ce fichier.
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
