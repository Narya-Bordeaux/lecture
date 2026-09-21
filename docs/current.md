# État courant

**Version : 0.17.0+30** — 21 septembre 2026

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
3. 🟡 **Textes et structure** — `validate()` classe chaque anomalie en *faux* ou
   *incomplet* (0.10.0), `loadDraft` ouvre une aventure inachevée, le lettrage du
   croquis est calculé (0.12.0), et **l'écran de construction marche** (0.14.0) :
   bouton « Ajouter », nombre de trajets, nature, nom, et chaque arrivée devient
   une carte prolongeable en dessous. Une aventure se crée aussi à partir de
   rien. **Reste l'enregistrement** — l'écran travaille en mémoire et rien ne
   l'écrit. Les récits d'arrivée et de départ restent aussi à saisir.
4. ⬜ **L'image** — la choisir, la copier, l'afficher. Pendant l'édition il
   faudra la charger **par chemin de fichier** : une image fraîchement ajoutée
   n'est pas dans le bundle, les assets étant scellés au build.
5. ⬜ **Le lexique et les listes** — saisir mots et découpages, unicité garantie,
   et composer les listes thématiques. Le modèle est posé depuis 0.17.0
   (`WordList`, `ContentWriter.writeWordLists`) ; reste l'écran.
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
aucun mot d'une famille donnée — question que 0.17.0 rend plus pressante, le
tirage se faisant désormais à deux étages.

**Les listes livrées font encore exactement la taille de la partie.** Le
dispositif de 0.17.0 est en place et éprouvé, mais il ne rapportera rien tant
qu'aucune liste n'aura plus de mots qu'il n'en faut : écrire du vocabulaire est
un travail d'auteur, pas de code.

## Dernières modifications

### 0.17.0+30 — Des listes plus grandes que la partie
- **Une liste est réutilisable et plus grande que ce qu'une partie en montre.**
  À l'entrée d'un lieu, le moteur tire quelques mots de chaque liste, après
  avoir retiré ceux qu'elle partage avec ses voisines. Rejouer la même journée
  ne redonne plus les mêmes mots.
- **La règle du mot ambigu change de main.** Elle tenait à la vigilance de
  l'auteur — 0.4.1 avait élagué onze mots partagés à la main — elle est
  désormais appliquée par la machine, avant que le mot n'atteigne l'écran.
  Écrire le même mot dans deux listes devient la façon de le déclarer ambigu
  *ici*.
- Ce que `validate()` signale, c'est le **manque** que l'exclusion laisse :
  *incomplet* s'il faut écrire d'autres mots, *faux* si une liste est
  entièrement absorbée par ses voisines.
- **Un troisième objet, `WordList`**, entre le lexique (qui refuse le doublon)
  et la famille (propre à un lieu). Il manquait : un mot doit pouvoir
  appartenir à plusieurs thèmes.
- Le contenu livré est **migré mot pour mot**, et son comportement est
  inchangé : sans `drawCount`, une liste joue entière.
- C'est le tri unique qui y gagne le plus : une seule liste d'objets
  hétéroclites peut servir tous les tris uniques, chacun retranchant son thème.
- 263 tests au vert, dont 23 nouveaux.

### 0.16.0+29 — Un troisième choix, et des listes bien à soi
- **La liste du reste n'était pas globale**, mais elle était `const` — et Dart
  canonise les constantes, donc deux tris uniques partageaient littéralement le
  même objet. Immutable, donc sans conséquence, mais il ne faut pas avoir à le
  démontrer : le `const` tombe, deux tests prouvent l'indépendance.
- **Troisième choix structurel : « Une fin »** (`TripKind.ending`). Le seul lieu
  qu'on puisse créer déjà achevé. Rien ne permettait de clore une journée.
- Les trois choix passent en liste explicite : chacun **dit ce que l'enfant y
  fera**. Ce sont trois mécaniques, pas trois habillages.
- `RadioListTile` avait changé d'API ; les dépréciations sont traitées.
- Le plan de navigation discuté (titre → image et zones, trajet → liste de mots,
  bouton « Valider ») est consigné dans `TODO.md`, à arbitrer.
- 240 tests au vert, dont 7 nouveaux.

### 0.15.0+28 — Le tri unique
- **Ce que faisait la « rencontre » n'est pas narratif, c'est une mécanique** :
  l'enfant trie entre **une liste et son complément**, au lieu de comparer
  plusieurs familles entre elles. Rien à comparer d'un mot à l'autre : chacun se
  juge seul contre un seul critère. Plus abstrait, plus difficile.
- `Stage.isSingleSort` : une famille **sans destination** est la liste du reste,
  et sa présence dit la mécanique. Rien de déclaré.
- Corollaire refusé par `validate()` : **un tri unique n'a qu'une seule
  sortie**. L'écran n'en propose pas davantage.
- **Le personnage devient un ornement**, posable sur n'importe quel lieu, dont
  aucune mécanique ne dépend. L'outil n'en invente plus.
- « sans issue » devient **« le reste »** — le mot se lisait comme une panne,
  alors que cette liste est la moitié du dispositif.
- Un manque disparaît : plus de `Character` fabriqué, donc plus de
  `characters.json` à écrire.
- 233 tests au vert, dont 10 nouveaux.


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
- **Un compte Google unique pour le bucket**, celui de l'auteur. L'usage est
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
