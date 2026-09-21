# État courant

**Version : 0.19.1+34** — 21 septembre 2026

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
   rien, et **les récits se saisissent** depuis 0.19.0, avec le nom du lieu et
   son illustration. **Reste l'enregistrement** — l'écran travaille en mémoire
   et rien ne l'écrit.
4. 🟡 **L'image** — **l'afficher est fait** : `contentImageProvider` lit le
   bundle ou le disque selon le chemin, ce qui lève la contrainte des assets
   scellés au build. **La choisir reste à faire** : l'éditeur demande un chemin
   au clavier, et un sélecteur suppose une dépendance tierce — à arbitrer.
5. ⬜ **Le lexique et les listes** — saisir mots et découpages, unicité garantie,
   et composer les listes thématiques. Le modèle est posé depuis 0.17.0
   (`WordList`, `ContentWriter.writeWordLists`) ; reste l'écran.
6. 🟡 **Rebrancher le calage** — **fait** : il s'ouvre depuis l'éditeur de
   lieu, sur l'étape en cours d'édition, et rend l'étape calée.
   **Enregistrer au lieu de copier** reste le manque, commun avec l'étape 3.

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

### 0.19.1+34 — Un lieu ne raconte pas son départ
- **`Narrative` perd `onCompletion`.** L'enfant clique un trajet, et c'est le
  lieu d'arrivée qui raconte, avec son propre texte.
- Le contenu livré le démontrait : « Devant la maison » annonçait l'arrivée à
  la plage au moment où on la quittait, avant que « La plage » ne la raconte.
- Une étape se joue en **deux temps** — récit puis jeu — au lieu de trois.
- **Trois textes ont été retirés du contenu**, listés dans `versions.md` : s'ils
  doivent revenir, c'est dans le `onArrival` du lieu suivant.
- 299 tests au vert.

### 0.19.0+33 — Ce qu'un lieu porte, et le seuil de la journée
- **Cliquer le titre d'une carte ouvre le lieu** (`StageEditorPage`) : nom,
  illustration, zones de dépôt, et les deux moments de récit.
- **Les listes de mots n'y sont pas** : elles appartiennent au trajet, pas au
  lieu, et une même liste sert à plusieurs endroits.
- Le calage s'ouvre de là, **sur l'étape en cours d'édition** — sinon l'auteur
  poserait ses zones sur l'image d'avant — et rend l'étape calée.
- **La page de garde a sa carte**, au-dessus du premier lieu, sans lettre : on
  n'en repart pas, on y entre. Elle existe même vide, et elle se retire.
- **Bundle ou disque, une seule règle** (`contentImageProvider`) : les assets
  sont scellés au build, une image fraîchement ajoutée vient du disque. Les
  quatre endroits qui affichent une image passent par là.
- **Choisir le fichier dans l'appareil reste à faire** : l'éditeur demande un
  chemin au clavier. Un sélecteur suppose une dépendance tierce, à arbitrer.
- 299 tests au vert, dont 28 nouveaux.


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
