# Versions

## Procédure de versioning — obligatoire

Toute session livrant une fonctionnalité ou une correction donne lieu à un
incrément de version. Une session qui ne touche qu'à la documentation de travail
(`current.md`, `TODO.md`) n'en demande pas.

### Format

`majeur.mineur.correctif+build` — par exemple `0.3.1+12`.

| Niveau | Quand l'incrémenter | Exemple |
|---|---|---|
| Majeur | Refonte, rupture de compatibilité des données sauvegardées | 0.9.0 → 1.0.0 |
| Mineur | Nouvelle fonctionnalité | 0.3.1 → 0.4.0 |
| Correctif | Correction de bug, ou nettoyage structurel sans fonctionnalité nouvelle | 0.3.0 → 0.3.1 |
| Build | **À chaque** incrément, quel qu'en soit le niveau. Jamais réinitialisé | +11 → +12 |

Tant que le jeu n'est pas jouable de bout en bout, la version reste en `0.x`.

### Les quatre fichiers à mettre à jour

Un incrément de version touche ces quatre fichiers, toujours, dans cet ordre :

1. `pubspec.yaml` — la ligne `version:`
2. `docs/versions.md` — une nouvelle entrée, la plus récente en haut
3. `docs/current.md` — la version en en-tête et la section « Dernières modifications »
4. `CLAUDE.md` — la ligne « Version actuelle » du §1

Contrôle rapide avant de clore une session, les quatre doivent concorder :

```bash
grep -rn "^version:" pubspec.yaml && grep -rn "Version actuelle" CLAUDE.md && head -3 docs/current.md
```

### Règle d'écriture

**Une entrée versionnée par incrément**, jamais d'ajout en vrac à l'entrée
précédente. La section « Dernières modifications » de `current.md` ne conserve que
les 2 ou 3 dernières versions ; les plus anciennes ne vivent que dans ce fichier.

---

## Historique

### 0.6.3+12 — 20 septembre 2026 — Intitulés au-dessus des zones, marge système

Deux défauts relevés sur appareil.

**« En voiture » s'affichait « En voitu… ».** L'intitulé était placé dans le
cadre, donc contraint par sa largeur, et Flutter l'abrégeait. Un enfant qui
apprend à lire ne doit jamais voir un mot tronqué — c'est le contraire de ce que
le jeu travaille.

L'intitulé est désormais posé **au-dessus** du cadre, centré sur lui et libre de
déborder de 90 points de chaque côté. Il porte `overflow: visible`, `maxLines:
1` et `softWrap: false` : il s'écrit en entier, quoi qu'il arrive. Le compteur
l'accompagne, ce qui laisse le cadre entièrement disponible pour les mots
déposés.

Conséquence technique : `SceneLayout` passe en `clipBehavior: Clip.none`, seul
le bord de l'écran coupant désormais un intitulé.

**Le bas du décor passait sous la barre de navigation**, masquant les pieds du
personnage. `computeSceneRect` accepte un `bottomInset` — la marge réservée par
le système — et cale l'illustration au-dessus.

Les tests d'interface visaient le centre de l'intitulé pour y lâcher un mot ;
celui-ci n'étant plus dans la zone, ils visent maintenant le cadre, identifié
par `FamilyDropZone.frameKeyFor`.

Deux tests ajoutés : l'un vérifie qu'aucun intitulé ne peut être abrégé ni rendu
plus étroit que son texte naturel, l'autre que l'illustration et ses zones
restent au-dessus de la marge système.

108 tests au vert.

### 0.6.2+11 — 20 septembre 2026 — L'illustration et les zones débordaient

Constaté sur appareil : l'illustration sortait de l'écran sur les côtés, et les
zones « En bus » et « À pied » étaient amputées.

L'illustration était recadrée pour remplir l'écran. Sur un Galaxy A54 — 1080 ×
2340, soit 1 : 2,17, contre 1 : 1,5 pour l'image — elle devait mesurer 1560 px
de large pour en couvrir la hauteur : **480 px sortaient**, 240 de chaque côté.
Les zones, qui collent au décor par construction, sortaient avec lui. Aucun
réglage de zone n'aurait corrigé cela : le recadrage lui-même était en cause.

L'illustration est désormais affichée **en entier** et **calée en bas** : le
personnage et le chemin restent visibles, et la bande libérée en haut est celle
qu'occupe déjà le bandeau des mots. Elle est comblée par `backgroundColor`, une
nouvelle donnée de contenu — `#4ab8fd` pour cette scène, la couleur relevée dans
son ciel, ce qui rend le raccord invisible.

Sur le A54, l'illustration occupe maintenant 0 → 1080 en largeur, et les trois
zones tiennent entre x = 22 et x = 1037.

**Le test qui manquait.** `computeSceneRect` est extraite en fonction pure, et
`test/ui/scene_geometry_test.dart` l'éprouve sur quatre appareils réels : image
entièrement visible, proportions gardées, calage en bas, chaque zone à l'écran
et assez grande pour un doigt. Les tests d'interface existants ne pouvaient rien
voir — ils tournent sans illustration, donc sans recadrage. Vérifié en
réintroduisant l'ancien calcul : neuf tests échouent, dont « chaque zone de
dépôt reste entièrement à l'écran » sur le A54.

102 tests au vert.

### 0.6.1+10 — 20 septembre 2026 — Assets manquants : le jeu ne s'ouvrait plus

Sur l'appareil, le jeu affichait « Le jeu n'a pas pu s'ouvrir ». La répartition
du contenu en sous-dossiers (0.6.0) n'avait pas été reportée dans
`pubspec.yaml`, qui ne déclarait que `assets/content/adventures/`.

**Flutter n'embarque pas les sous-dossiers** : une entrée terminée par `/` ne
prend que les fichiers de ce répertoire précis. `index.json`, `characters.json`
et les trois lexiques n'étaient donc pas dans l'application. Le chargement
échouait dès le premier fichier lu.

Rien ne pouvait le signaler plus tôt : l'application compilait, et les 78 tests
passaient puisqu'ils lisent le disque, pas le bundle.

- Les quatre répertoires sont déclarés dans `pubspec.yaml`.
- `test/infrastructure/declared_assets_test.dart` parcourt `assets/` et vérifie
  que chaque fichier est couvert par une déclaration. C'est le seul test qui
  regarde ce qui sera réellement livré. Éprouvé contre l'ancien pubspec : il
  nomme les cinq fichiers manquants.
- L'écran d'erreur affiche désormais le diagnostic en mode développement. Le
  chargement produit des messages précis — mot inconnu, personnage absent — et
  l'interface les jetait, ce qui obligeait à chercher à l'aveugle.

79 tests au vert.

### 0.6.0+9 — 20 septembre 2026 — Format de contenu en plusieurs fichiers

Le contenu tenait dans un seul fichier, qui aurait explosé avec six thèmes et
des rencontres. Il se répartit désormais en quatre sortes de fichiers, décrites
par `docs/Format_fichier_aventure.md` — un document destiné à qui écrit du
contenu sans toucher au code.

- `index.json` : le sommaire, qui dit ce qui existe sans rien charger.
- `lexicon/*.json` : le vocabulaire par domaine. **Chaque mot n'est défini
  qu'une fois** : dupliqué, il finirait découpé de deux façons différentes, et
  l'enfant verrait les deux.
- `characters.json` : les personnages, réutilisables d'une aventure à l'autre.
- `adventures/*.json` : les lieux, qui ne citent que des identifiants.

Nouveaux modèles : `Lexicon`, `Character`, `Encounter`, `Narrative`,
`ContentIndex`. Le chargement se fait en trois temps dans `ContentRepository`,
derrière une abstraction `ContentSource` — les assets en jeu, le disque en test.

**Récit à deux temps.** Chaque lieu porte un `onArrival`, affiché avant de
jouer, et un `onCompletion`, affiché au départ. Ils occupent un écran à eux
(`StoryMomentPage`) plutôt que de se glisser dans l'écran de jeu : le bandeau
des mots touche déjà les zones ancrées haut dans le décor, l'épaissir aurait
rouvert le défaut corrigé en 0.3.0.

**Rencontres.** Une étape portant un `character` est une rencontre ; sa réplique
remplace la consigne au-dessus des mots. Le classeur de rebut est une famille
**sans destination** : `destination` devient optionnel, et une telle famille
n'ouvre aucun chemin même complète. Aucune notion de « mot intrus » n'a été
nécessaire.

**Simplification** : les mots sont portés par les familles, `Stage.words` en est
dérivé. La liste déclarée en double disparaît, et avec elle le risque qu'elle
diverge des familles.

Pas de champ « type d'étape » : la structure le dit déjà. Un `character` signale
une rencontre, l'absence de famille une arrivée.

**Défaut trouvé par les tests** : `Lexicon.fromJson` écrasait silencieusement un
mot défini deux fois dans le **même** fichier — le cas le plus probable, une
ligne copiée puis mal reprise. Seuls les doublons entre fichiers étaient
détectés. Les deux le sont désormais, en nommant les coupables.

78 tests au vert, `flutter analyze` sans erreur.

### 0.5.0+8 — 20 septembre 2026 — Listes pleines, une seule aide

Deux décisions de conception, prises ensemble parce qu'elles reposent sur la
même observation : **le nombre de familles est déjà une aide**.

**Listes pleines.** Une famille s'ouvre lorsque tous ses mots sont classés, et
non plus au bout d'un objectif raccourci. `goal` disparaît du contenu, le champ
restant disponible si un niveau veut en demander moins. Remplir entièrement une
catégorie réduit le choix pour les mots suivants : c'est une aide progressive
qui ne coûte rien.

**L'illustration est retirée.** Avec trois familles, un enfant qui a oublié le
sens d'un mot finit par n'avoir plus qu'un choix ; montrer l'image en plus
reviendrait à donner la réponse. Sont supprimés : `Hint.illustration`,
`HintPolicy.illustrationThreshold` et `Word.illustrationAsset`, ce dernier
n'ayant jamais été rempli. Le découpage syllabique reste l'unique aide, dès la
première erreur.

Conséquence assumée, notée dans la spécification : la fin d'une étape devient
facile, puisque les derniers mots se classent sans être lus une fois deux
familles pleines. C'est un soulagement pour un enfant en difficulté et sans
intérêt pour un bon lecteur — d'où le nombre de familles comme axe de
progression.

Le choix du chemin arrive désormais tard, une fois l'essentiel de l'étape
classé, et les trois destinations sont souvent ouvertes en même temps. Le choix
est donc complet plutôt que précoce.

66 tests au vert, `flutter analyze` sans erreur.

### 0.4.1+7 — 20 septembre 2026 — Listes de sept mots, sans ambiguïté

Relecture du contenu : onze mots valaient pour deux familles à la fois et ont
été retirés — navette, car, voyageur (bus) ; ceinture, pneu, parking, capot,
phare (voiture) ; trottoir, semelle, lacet (marche).

« En voiture » s'est retrouvée à cinq mots, faute de vocabulaire qui lui soit
propre : `radio` et `clé` l'ont complétée, deux mots de la voiture familiale que
le bus ne revendique pas. Les trois familles comptent maintenant sept mots.

L'objectif passe de 5 à 4. Sur des listes de sept, un objectif de 5 laissait
trop peu de marge, et surtout : plus l'objectif est haut, moins le choix du
chemin est un vrai choix, l'enfant ayant déjà classé la plus grande partie de
l'étape quand une famille atteint son but.

La spécification gagne une section sur le **champ lexical des familles**. Le
fond du problème est structurel : « En bus » et « En voiture » partagent toute
la mécanique — moteur, roue, frein, siège, phare, ceinture — car un bus est une
voiture en plus grand. Seuls tiennent les mots propres à l'usage. Pour une
nouvelle scène, mieux vaut choisir des familles aux lexiques naturellement
séparés que d'élaguer après coup.

Les listes n'ont plus à être de même taille : un test le vérifie, en s'assurant
seulement qu'aucune famille ne demande plus de mots qu'elle n'en possède.

66 tests au vert, `flutter analyze` sans erreur.

### 0.4.0+6 — 20 septembre 2026 — Réserve de dix mots par famille

Chaque famille dispose désormais d'une liste de dix mots. Six sont proposés à la
fois ; un mot bien classé est remplacé par un mot de la réserve.

- `Stage.visibleWordCount` : combien de mots sont proposés en même temps (6).
- `WordFamily.goal` et `requiredCount` : combien de mots ouvrent la destination.
- `StageEngine` : emplacements et réserve. `shuffledWords` devient `visibleWords`,
  une liste d'emplacements où un vide vaut `null`.
- `StageState.remainingInSupply` et `placedCountIn`.
- Contenu : trois listes de dix mots pour « En bus », « En voiture » et « À pied ».

Le mot qui arrive reprend **exactement** l'emplacement libéré, et lui seul : les
autres ne bougent pas, pour que l'enfant ne perde pas des yeux celui qu'il était
en train de déchiffrer. Un mot mal classé ne déclenche aucun renouvellement.

**Objectif plus court, à valider.** Avec dix mots par famille, la règle
précédente — classer toute la liste — aurait demandé près de trente placements
avant d'ouvrir le moindre chemin, bien au-delà de l'attention d'un enfant de six
ans. Une famille s'ouvre donc au bout de cinq mots, réglable famille par famille
dans le contenu. La zone affiche l'avancement vers cet objectif, pas vers la
réserve, et le compte est borné pour ne jamais afficher « 6 / 5 ».

Conséquence du tirage libre, également à valider : il peut arriver qu'aucun mot
d'une famille donnée ne soit à l'écran. L'enfant classe alors ailleurs, ce qui
renouvelle la réserve. Cela l'oblige à lire tous les mots, mais peut contrarier
qui vise une destination précise.

Les tests d'interface ne peuvent plus viser un mot écrit en dur, puisque les six
mots affichés sont tirés de trente. Ils mènent un moteur témoin avec la même
graine, qui dit lesquels sont à l'écran.

65 tests au vert, `flutter analyze` sans erreur.

### 0.3.0+5 — 20 septembre 2026 — Interface du niveau test

Le niveau test devient jouable.

- `lib/ui/pages/` : `StagePage` (une étape) et `AdventurePage` (enchaînement des
  étapes, chargement du contenu, étapes terminales).
- `lib/ui/widgets/` : `SceneLayout` (décor et zones), `FamilyDropZone`,
  `DraggableWordLabel`, `Shake`.
- `lib/ui/strings/ui_strings_fr.dart` : chaînes de l'interface.
- `lib/main.dart` : point d'entrée réel, portrait verrouillé.
- Domaine : `RelativeArea`, `WordFamily.area`, `Stage.backgroundAsset`.

Décisions d'interface prises en session : portrait pour le MVP, étiquette qui se
loge dans sa zone, retour animé au refus, bouton « Partir » en bas d'écran.

Contenu revu pour la scène illustrée : la famille « En train » devient « En bus »,
et les mots sont choisis pour qu'aucun n'apparaisse dans le nom de sa famille —
« bus » dans « En bus » se classerait en comparant les lettres, sans être compris.
`Stage.validate()` détecte désormais ce cas, ainsi que les zones qui débordent de
l'illustration ou se chevauchent.

**Défaut trouvé et corrigé pendant les tests** : le bandeau des mots recouvrait la
zone du bus sur un écran de 360 × 640. Le doigt y était intercepté et le mot
n'atteignait jamais sa cible, sans aucun signe. En cause, les mots longs qui
passaient à la ligne et faisaient grandir le bandeau. Les étiquettes tiennent
maintenant sur une seule ligne, quitte à réduire la police, et
`test/ui/real_content_layout_test.dart` monte l'étape réelle sur trois formats
d'écran pour que cela ne puisse pas revenir sans être vu.

50 tests au vert, `flutter analyze` sans erreur. Le rendu visuel n'a pas pu être
observé : aucun build n'est possible en session cloud.

### 0.2.0+4 — 20 septembre 2026 — Moteur d'étape et niveau test

Première livraison de code applicatif. Le moteur applique les règles de classement ;
rien n'est encore affiché.

- `lib/domain/models/` : `Word` (texte, syllabes, illustration), `WordFamily` (mots
  et destination desservie), `Stage`, `Adventure`, `Hint`, `HintPolicy`.
- `lib/application/stage_engine.dart` : `StageEngine` et `StageState`. Placement
  accepté ou refusé, erreurs comptées par mot, aides débloquées aux seuils,
  destination ouverte par la complétion d'une famille, départ explicite.
- `lib/infrastructure/content/` : chargement JSON, avec validation du contenu.
- `assets/content/adventures/grisbie_beach.json` : le niveau test.
- 31 tests, `flutter analyze` sans erreur.

Décisions prises en session et reportées dans la spécification (v0.5) : classement
libre sans engagement préalable, destination rendue disponible et non imposée,
seuils d'aides à 1 et 5 erreurs, étapes imbriquées.

`validate()` sur `Stage` et `Adventure` détecte les incohérences de contenu, dont
les mots ambigus que la spécification proscrit. Un test les vérifie sur le niveau
livré, pour que la règle soit tenue automatiquement plutôt que de mémoire.

### 0.1.2+3 — 20 septembre 2026 — Flutter disponible dans l'environnement cloud

Les sessions cloud ne disposaient ni de `flutter` ni de `dart` : aucune
vérification du code Dart n'y était possible, ce qui est incompatible avec un
développement en TDD.

- `.claude/hooks/session-start.sh` : installation du SDK Flutter au démarrage de
  session. Version épinglée (3.47.5), archive vérifiée par empreinte SHA-256,
  installation idempotente, PATH propagé à la session. Le script sort immédiatement
  hors environnement distant, pour ne rien installer sur le poste de développement.
- `.claude/settings.json` : enregistrement du hook.
- `analysis_options.yaml` et `pubspec.lock` : mis à jour par l'outil Flutter lors de
  la première résolution des dépendances avec le SDK épinglé.
- `CLAUDE.md` §2 réécrit : l'environnement n'est plus décrit comme dépourvu de
  Flutter.

Mesures : démarrage à froid 1 min 34 s (téléchargement, vérification, extraction,
artefacts, dépendances), reprise à chaud 0,9 s. `flutter analyze` sans erreur et
`flutter test` au vert.

### 0.1.1+2 — 20 septembre 2026 — Retrait de la plateforme iOS

iOS n'est pas une plateforme visée et aucun compte développeur Apple n'est ouvert.
Le dossier `ios/` représentait 27 des 69 fichiers suivis, entièrement générés et
jamais personnalisés.

- Suppression du dossier `ios/`.
- `.metadata` : retrait de l'entrée de migration `ios` et du fichier `ios` de
  `unmanaged_files`. Édité à la main faute de Flutter dans l'environnement cloud,
  alors que ce fichier est normalement maintenu par l'outil.
- `docs/TODO.md` : commande de régénération consignée, pour que le retour d'iOS
  reste trivial.

### 0.1.0+1 — 20 septembre 2026 — Mise en place du cadre de travail

Préparation du dépôt en vue d'une éventuelle publication en open source.

- `.gitignore` durci : `.vscode/`, `.env` et variantes avec exception
  `.env.example`, `.claude/settings.local.json`.
- `CLAUDE.md` créé : périmètre du projet, environnement, conventions vérifiables et
  règle de séparation moteur / interface.
- `docs/current.md`, `docs/versions.md` et `docs/TODO.md` créés.
- Version ramenée de `1.0.0+1` (valeur générée par `flutter create`) à `0.1.0+1`,
  le code applicatif n'étant pas encore écrit.

Aucun code applicatif livré à ce stade.
