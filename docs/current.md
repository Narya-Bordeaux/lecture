# État courant

**Version : 0.35.0+54** — 23 septembre 2026

## Où en est le projet

**Le niveau test est jouable.** L'étape de départ s'affiche sur l'illustration
`Grisbie_plage2.jpg` : six mots en haut, trois zones translucides posées sur le
bus, la voiture et le sentier, glisser-déposer et bouton de départ. **Aucune
aide à la lecture** depuis 0.33.0 : un mot mal placé est refusé, et c'est tout.
Chaque famille puise dans une liste pleine de sept mots, et un mot bien classé
est remplacé sur place par un mot de la réserve. La spécification est en version
de travail 0.8.

Le contenu vit désormais dans plusieurs fichiers reliés par un sommaire, décrits
par `docs/Format_fichier_aventure.md`. Les mots y sont regroupés en **listes
thématiques réutilisables**, qu'une famille cite au lieu de les porter. La boutique de la gare est un **tri
unique** : l'enfant y trie entre une liste et tout le reste. Il n'y a plus
de personnage (0.34.2).

**Un outil d'auteur existe**, sur un second point d'entrée `lib/main_author.dart`.
Il cale les zones de dépôt au doigt sur l'étape réelle, et les enregistre avec
l'aventure. Le
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
4. ✅ **L'image** — **elle est devenue du contenu** (0.28.0), et **ça
   marche des deux côtés** : éprouvé dans Chrome puis sur le téléphone, le
   22 septembre 2026. Choisie, elle s'écrit aussitôt dans l'arbre sous
   `pictures/…`, par le même puits que le JSON, et `ContentPictureImage` la
   relit par la source.
5. ✅ **Le lexique et les listes** — fait en trois livraisons
   convenues avec l'auteur :
   1. ✅ **La nature se dit sur la carte du lieu** (0.30.0) : plusieurs
      listes, tri unique ou fin. Sept mots par liste.
   2. ✅ **Le moteur des listes** (0.31.0). Pas de mot seul : on crée une
      liste ou on en réutilise une. **Tri unique, option C** : l'auteur choisit le thème,
      et coche les listes où le jeu peut puiser les mots « autre » — le jeu y
      tire des mots qui ne sont pas du thème. Tirer dans *tout* le
      vocabulaire a été écarté : « banane », absente de la liste « Ce qui se
      mange » mais présente ailleurs, serait refusée à l'enfant qui la range
      à juste titre. L'enregistrement écrit désormais le lexique et les
      listes modifiées, chacun dans son fichier.
   3. ✅ **L'écran de liste** (0.32.0), ouvert en touchant un trajet. La
      carte dit pour chaque liste : « une fois retirés les mots communs aux
      autres listes, en reste-t-il assez pour jouer ? » — `7/7`, `3/7`, ou
      « pas de liste ». **Jamais ouvert pour de vrai** : à éprouver sur le
      téléphone et dans Chrome.
6. ✅ **Rebrancher le calage** — il s'ouvre depuis l'éditeur de lieu, sur
   l'étape en cours d'édition, **montre enfin son illustration**, et s'enregistre
   avec l'aventure : plus de JSON à copier (0.29.0).

**Le dépôt distant fonctionne, éprouvé le 22 septembre 2026** — dans Chrome
**et sur le téléphone**, sur le projet `grisbie-43ee9` : connexion par e-mail,
dépôt du contenu et des images, relecture depuis le dépôt. L'outil liste les
aventures qui n'existent que là, et les ouvre. C'était la première exécution
réelle de tout ce qui a été écrit depuis 0.23.0.

**Un avertissement à ne pas chasser** : sur Android, chaque appel à Storage
journalise « No AppCheckProvider installed ». C'est un avertissement, pas une
panne — App Check n'est ni installé ni imposé, et n'apporterait rien ici. Voir
`Noms_et_identifiants.md`.

Le dernier obstacle a été le **CORS**, et il ne se devinait pas : une origine
précise ne suffit pas, parce que Firebase **redirige** vers
`storage.googleapis.com` et que le navigateur revérifie l'autorisation sur la
nouvelle adresse. Marche à suivre dans `Commandes.md`.

Deux sujets antérieurs restent ouverts, sans être le chantier : la gare et la
boutique n'ont ni décor ni zones placées, et le **tirage libre** peut ne proposer
aucun mot d'une famille donnée — question que 0.17.0 rend plus pressante, le
tirage se faisant désormais à deux étages.

**Les listes livrées font encore exactement la taille de la partie.** Le
dispositif de 0.17.0 est en place et éprouvé, mais il ne rapportera rien tant
qu'aucune liste n'aura plus de mots qu'il n'en faut : écrire du vocabulaire est
un travail d'auteur, pas de code.

## Dernières modifications

### 0.35.0+54 — L'énoncé sur la scène
- **Le texte d'arrivée d'un lieu de jeu est son énoncé**, affiché en haut de
  la scène au-dessus des mots. Plus d'écran de récit intercalé, plus de
  consigne générique.
- Les trois tolérances héritées sont retirées.
- **Défaut mesuré** : sur un petit téléphone, un énoncé de deux phrases
  recouvre la zone du bus. À trancher avec l'auteur.
- 509 tests au vert.

### 0.34.2+53 — Plus de personnage
- **Décision de l'auteur** : le personnage mêlait narration et mécanique ; la
  mécanique vit dans la structure, le reste relève du récit. Modèle, fichier
  `characters.json` et réplique retirés.
- **Règle nouvelle** : le jeu n'est pas en ligne, aucune compatibilité ne se
  construit (CLAUDE.md §1).
- **En discussion** : l'énoncé en haut de la scène de jeu, et un type « page
  de récit » pour la page de garde, les transitions et les fins (`TODO.md`).
- 508 tests au vert.

### 0.34.1+52 — Un lieu rouvert se redéfinit sur place
- **Défaut vu par l'auteur** : après « Rouvrir ce lieu », l'écran de
  structure ne disait que « Choisissez sur la carte » — une impasse.
- Il offre désormais les trois réponses de la carte — plusieurs listes, tri
  unique, fin — ainsi qu'« Ajouter des trajets » et « Ajouter la sortie ».
- 512 tests au vert.

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
- **Un mot n'est que son orthographe** : le découpage syllabique a quitté le
  contenu avec l'aide qu'il servait (0.33.0).
- **Contenu pédagogique séparé du code** : les mots, familles et niveaux vivent dans
  `assets/content/` en JSON.
- **Le classement est libre, le départ est choisi** : compléter une famille ouvre sa
  destination sans y envoyer l'enfant. Plusieurs destinations peuvent être ouvertes
  en même temps ; l'enfant part quand il le décide.
- **Aucune aide à la lecture** (décision de l'auteur, 23 septembre 2026) : le
  découpage syllabique après une erreur est retiré, l'illustration avait déjà
  été écartée — avec trois familles, les possibilités se réduisent d'elles-mêmes
  à mesure que les catégories se remplissent.
- **Listes pleines** : une famille s'ouvre quand tous ses mots sont classés.
  Remplir une catégorie est en soi une aide pour les mots suivants.
- **Étapes imbriquées** : une destination atteinte ouvre une étape de même nature,
  avec ses propres familles. Le modèle est récursif, un seul moteur sert partout.
- **Un lieu raconte son arrivée, jamais son départ** : la narration appartient
  à celui qui accueille. Un récit de départ a existé, et disait la même chose
  deux fois.
- **Contenu en plusieurs fichiers** : un sommaire, des lexiques par domaine, des
  listes, les aventures. Un mot n'est défini qu'une fois.
- **Leurres écrits à la main** : jamais ramassés automatiquement, sous peine de
  sortir un mot appartenant vraiment au thème et de refuser une bonne réponse.
- **La nature d'un lieu se dit sur sa carte** : plusieurs listes, tri unique,
  ou fin. La question est « que fait l'enfant ici ? », et elle se pose au
  lieu, pas au trajet qui y mène.
- **Sept mots par liste** : ce que chaque liste met en jeu dans un lieu écrit
  par l'outil. Une liste peut en compter bien davantage.
- **Tri unique, option C** : le thème est une liste, et les mots « autre » se
  tirent dans des listes que l'auteur coche comme sûres pour ce thème, moins
  les mots du thème. Ni liste « autre » écrite exprès (option A), ni tirage
  dans tout le vocabulaire (option B, qui refuserait une bonne réponse).
- **Une boucle est permise** : un trajet peut rejoindre n'importe quel lieu
  déjà écrit. L'outil la signale, *à vérifier*, sans bloquer le jeu.
- **Un lieu ne disparaît que sur demande** : retirer un trajet laisse son lieu,
  détaché, que l'auteur supprime depuis sa carte s'il le veut.
- **L'outil n'est jamais entre les mains d'un enfant** : il tolère tout, et
  prévient. C'est le jeu qui refuse une aventure non jouable.
- **Listes réutilisables, plus grandes que la partie** : le moteur en tire
  quelques mots à l'entrée du lieu, après avoir retiré ceux qui sont communs à
  plusieurs listes du même lieu. Le mot ambigu n'est plus interdit à l'auteur,
  il est retiré par la machine — et rejouer donne d'autres mots.

## Points ouverts

Les questions fonctionnelles non tranchées sont listées en fin de
`Specification_jeu_decouverte_lecture.md` et ne sont pas reprises ici.
