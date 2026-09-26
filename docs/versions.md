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

### 0.52.0+74 — 26 septembre 2026 — Un dossier d'images par aventure

Trois demandes de l'auteur.

- **L'accueil dit à quoi l'on joue** : « Lis les mots et groupe-les par
  famille », en bas de l'écran (option A). `HomeLayout` lui réserve une
  bande au-dessus de la marge du bas, et le vide libre se partage toujours
  en trois ; sur un écran étroit la phrase rapetisse plutôt que de passer à
  la ligne. Le titre de l'accueil devient un nœud d'accessibilité à part,
  sans quoi il se lisait d'un bloc avec la phrase.
- **Un sous-dossier d'images par aventure** : `pictures/<id>/`. Les dix
  images de la plage passent dans `pictures/grisbie_plage/`, l'aventure et
  le sommaire suivent, et le dossier est déclaré au `pubspec`. `bonjour.jpg`
  reste à la racine, son aventure n'existant pas encore. `PictureFolder`
  (domaine) déduit le dossier du chemin et regroupe ; le choix d'une image
  **s'ouvre sur le dossier de l'aventure**, « Toutes les images » montre les
  autres par dossier (option B). Sans dossier, il dit lequel créer et le
  déclarer. Le refus d'intégration nomme le dossier de l'aventure.
- **La page de garde conseille son format** : 3:2 en largeur, celui de la
  vignette. Une alerte sous le champ, jamais un refus : l'image est montrée
  entière, mais ne servirait pas de vignette sans recadrage.
- Tests : 764 au vert. Accueil capturé dans Chromium en 390 × 844 et
  360 × 640 ; la vignette s'y lit depuis son nouveau dossier.

### 0.51.0+73 — 25 septembre 2026 — Cinq mots par boîte, six à l'écran partout

Deux décisions de l'auteur, sur deux nombres qu'aucun écran ne montrait.

- **Le nombre d'étiquettes à l'écran devient une constante**,
  `Stage.visibleWordCount` = 6 : le champ `visibleWordCount` quitte le
  modèle et les fichiers. C'est lui qui laissait la gare à 4 mots (0.50.1).
- **Chaque boîte tire cinq mots au lieu de sept** (`Stage.defaultDrawCount`),
  « autre chose » comprise : « 7, c'est beaucoup pour un enfant ».
- **Ce nombre n'est plus écrit dans les fichiers.** L'outil le posait sur
  chaque lieu à ses premières listes (0.42.0), si bien que cinq lieux sur
  huit portaient `"drawCount": 7` : changer le défaut les aurait laissés à
  sept, en silence. Les 7 sont retirés du contenu livré,
  `AdventureBuilder.defaultDrawCount` disparaît, et le défaut du domaine
  joue partout. Les champs `drawCount` restent possibles dans le format ;
  le document dit de ne pas les écrire d'ordinaire.
- Tests : les attentes à sept passent à cinq ; le test de la réserve de
  mots, qui reposait sur quatre cases, en compte six. 737 au vert.

### 0.50.1+72 — 25 septembre 2026 — La gare montre six mots

- **L'auteur a écrit les 22 textes de trajet** (commit `4324613`), et revu
  des noms de boîtes (« le train », « quelque chose à acheter »,
  « d'autres mots ») : l'aventure livrée est de nouveau jouable.
- **La gare ne proposait que 4 mots à la fois** : son fichier portait
  `"visibleWordCount": 4`, écrit en 0.12.0 à l'époque du contenu inventé,
  et conservé quand l'auteur a réécrit l'aventure dans l'outil — aucun écran
  ne montre ce réglage. Remis à 6, comme les autres lieux. Savoir s'il faut
  le montrer dans l'outil ou en faire une constante est posé à l'auteur.
- Tests : les jeux de données en JSON écrits avant 0.50.0 reçoivent leurs
  deux textes de trajet ; les tests qui citaient d'anciens noms lisent
  désormais ceux du contenu (le bouton de départ lit l'action écrite).
  **737 tests au vert.**

### 0.50.0+71 — 25 septembre 2026 — Les textes d'un lieu, en diapositives

**La narration se restructure autour du trajet**, d'après l'exemple de
l'auteur : sur la boîte le thème (« En voiture »), boîte pleine un texte
(« Tu as trouvé tous les mots « en voiture ». Tu peux prendre la voiture. »),
sur le bouton une action (« Prendre la voiture »), puis le lieu atteint
raconte son arrivée (« Un petit arrêt au garage, la radio est à fond… »).
**Le lieu d'arrivée n'est jamais nommé avant d'y être.**

- `WordFamily.departureLabel` (`"departureLabel"`), nouveau. Avec
  `completionText`, **obligatoire** sur tout trajet qui mène quelque part :
  `validate()` rend le trajet *à finir* (`ContentIssue.isMissingText`).
  Décision de l'auteur, prise en sachant que le jeu livré ne s'ouvrirait
  plus jusqu'à ce qu'il les écrive.
- **Rien n'est pré-écrit** : le texte composé de 0.49.0, le texte proposé
  dans l'éditeur et sa mécanique (non enregistré tant qu'inchangé) sont
  retirés, `Adventure.locationNames` avec eux. `CompletionMessage` rend le
  texte de l'auteur. Dans un lieu inachevé que l'outil fait essayer,
  « Bravo ! » paraît seul et le bouton reprend « Partir … ».
- **La carte d'un lieu** : ligne 1 l'apparence — `StageAppearancePage`, ex
  `StageEditorPage` réduit à l'image et aux cadres ; ligne 2 la nature,
  « Textes » (« Textes · 2 à écrire » tant qu'il en manque) et « Ajouter ».
  Les textes manquants ne s'y listent plus un par un.
- **`StageTextsPage`** : les textes du lieu en diapositives, dans l'ordre où
  l'enfant les vit — l'énoncé dans la fenêtre d'arrivée, les noms des boîtes
  posés sur l'illustration à la place de leur cadre, le « Bravo ! » et le
  bouton de chaque trajet ; une seule diapositive pour une fin. Case vide en
  jaune. Un lieu à la fois (décision de l'auteur).
- **Renommer un trajet quitte l'écran de structure** : le nom d'une boîte
  s'écrit sur son cadre, dans les textes.
- Tests : les tests de l'outil chargent l'aventure livrée en brouillon
  (`loadRealDraft`), comme l'outil ; ceux qui ont besoin d'une aventure
  jouable y posent des textes **de test** (`withTestTripTexts`), jamais
  versés dans le contenu. Le constructeur de familles des tests pose ces
  deux textes par défaut (`withTexts`).
- **État : 56 tests en échec**, tous pour la même raison — l'aventure livrée
  n'a pas encore ses 22 textes de trajet, et le jeu la refuse. Vérifié
  fichier par fichier. Vu en capture dans Chromium (outil d'auteur).

### 0.49.0+70 — 25 septembre 2026 — « Bravo ! »

**Une boîte pleine dit « Bravo ! »**, selon l'option C retenue par l'auteur :
un titre fixe, et dessous un texte pré-écrit que l'auteur peut changer.

- Le dernier mot rangé, la boîte passe au vert ; 0,45 s plus tard s'ouvre
  `CompletionPopup` : « Bravo ! » en vert, Grisbie le pouce levé qui déborde
  du coin haut gauche (image fournie par l'auteur,
  `assets/grisbie_bravo.webp`), le texte dessous. Un toucher n'importe où la
  ferme ; la barre de départ attend dessous.
- `CompletionMessage` (Dart pur) décide du texte : celui de l'auteur
  (`WordFamily.completionText`, `"completionText"` dans le fichier), sinon
  « Tu as rangé tous les mots « En bus ». Tu peux partir vers la gare, ou
  ouvrir un autre chemin. » — sans l'autre chemin quand il n'en reste pas,
  sans nom de lieu quand l'outil fait essayer un lieu seul. Seul l'article
  prend une minuscule. Espaces insécables dans les guillemets : la capture
  montrait un « seul en fin de ligne.
- **« Autre chose » n'annonce rien** (décision de l'auteur).
- **L'éditeur de lieu** : un champ par trajet, pré-écrit, derrière un
  « Bravo ! » affiché mais non saisissable, et « Revenir au texte proposé ».
  Le texte proposé gardé tel quel **n'est pas enregistré** : il suit ainsi
  les renommages et la fin adaptative. `Adventure.locationNames` fournit les
  noms de lieux au jeu comme à l'outil.
- Règle « un lieu ne raconte pas son départ » : maintenue. Ce texte dit ce
  qui vient d'être fait ici, au moment du choix ; la note de l'éditeur le
  rappelle.
- 24 tests nouveaux (moteur, fenêtre, éditeur). Deux tests existants ont dû
  fermer la fenêtre avant de continuer, comme l'enfant
  (`dismissCompletion`). 731 au vert ; vu en capture Chromium.

### 0.48.0+69 — 25 septembre 2026 — L'icône de Grisbie

**L'application a l'icône de Grisbie**, d'après le logo de l'accueil, et
l'écran de chargement se fond dans l'accueil. Choix de l'auteur sur planche :
cadrage A1 (l'image presque entière), crayon pour l'outil d'auteur, web
compris.

- **Icône adaptative** (Android 8 et plus) : le téléphone choisit la forme et
  ne montre que le centre (72 dp sur 108). Une icône de repli, déjà
  arrondie, sert Android 7.
- **Outil d'auteur** : les mêmes images, marquées d'un crayon dans une
  pastille, rangées dans `src/auteur/res`, qui a priorité sur `src/main`. La
  pastille reste dans le cercle que toute forme conserve — un premier jet la
  faisait déborder, corrigé avant intégration.
- **Écran de chargement** : Android 12 et plus impose une icône rognée en
  cercle sur une couleur — c'est l'icône, sur le bleu de l'accueil
  (`#DCEBF7`). Avant Android 12, le logo en ovale bordé de blanc, comme sur
  l'accueil. Le fond de la fenêtre prend le même bleu, sans éclair blanc
  avant la première image.
- **Web** : favicon, icônes ordinaires et « maskable », couleurs du
  manifeste. Une seule icône, les deux points d'entrée partageant `web/`.
- `tool/generate_app_icons.py` (Python et Pillow) produit les images ;
  `app_icon_test.dart` vérifie tailles, présence et références. **Rien n'a
  été construit pour Android** : le rendu reste à voir sur le téléphone.
  707 tests au vert.

### 0.47.1+68 — 25 septembre 2026 — « Autre chose »

**La liste du reste s'appelle « Autre chose »**, décision de l'auteur : « Les
autres », posé en 0.46.0, se lisait moins bien. Le nom que l'outil donne à une
liste du reste neuve, sa mention sur la carte du parcours, et les quatre zones
de l'aventure livrée. Une liste neuve naît `autre_chose` ; les identifiants
livrés restent `le_reste`, un identifiant ne suivant pas le nom.

### 0.47.0+67 — 25 septembre 2026 — Le geste de l'enfant

L'auteur voit régulièrement des enfants lâcher un mot hors de la boîte et
croire qu'ils se sont trompés. **La cause probable n'était pas le doigt qui
bouge** : l'étiquette suit le doigt en se tenant au-dessus de lui, et
Flutter cherchait la zone *sous le doigt*. Un mot vu dans la boîte, près du
bord bas, repartait donc — le doigt, lui, était déjà sorti.

- **Le mot compte là où on le voit** : `Draggable.feedbackOffset` vise le
  centre de l'étiquette, mesurée après mise en page (la taille du texte
  peut être grossie par les réglages du téléphone). Contre-épreuve faite :
  sans cette ligne, les deux tests du cas échouent.
- **Survol franc** : la boîte passe au blanc presque opaque (0,9), bordure
  épaisse, légèrement grossie. Le retour arrive avant le lâcher, quand
  l'enfant peut encore corriger son geste.
- **Lâcher dans le vide ≠ erreur** : le mot revient en glissant à sa case,
  sans trembler, et les boîtes clignotent deux fois (`Blink`). Un mot refusé
  tremble toujours, et ne fait rien clignoter.
- **Le reflet** (`Shine`) : la dernière boîte rangée, une bande dorée passe
  sur chaque mot dans l'ordre de lecture, qui grossit un instant — un peu
  moins d'une seconde en tout. Une seule fois par arrivée.
- La **marge invisible** autour des boîtes, proposée, est écartée pour
  l'instant par l'auteur : à décider après l'essai au doigt.
- Les tests d'écran visent désormais avec le mot, comme l'enfant
  (`dragWordTo`). 8 tests nouveaux ; 696 au vert. Vu en capture Chromium.

### 0.46.0+66 — 25 septembre 2026 — La mise en place d'un lieu

**Un lieu se découvre avant de se jouer**, selon la demande de l'auteur :
le décor seul, un quart de seconde ; l'énoncé au centre, dans une fenêtre
que l'enfant ferme d'une petite flèche — et d'elle seule, pour qu'un toucher
à côté ne la ferme pas avant lecture ; puis le cartouche paraît, et chaque
boîte de rangement se présente au centre de la scène. Touchée, elle va se
ranger à sa place, et la suivante vient. Les mots se lisent pendant ce
temps, mais ne bougent qu'une fois la dernière boîte rangée.

- `StageIntroduction` (`lib/application/`, Dart pur) décide du déroulé :
  les quatre temps, l'ordre des boîtes — **ordre de création, « les
  autres » toujours en dernier** —, ce qui se saute (pas d'énoncé, pas de
  boîte placée), et quand les mots se libèrent. Immuable, 15 tests.
- **Option A de l'auteur : le cartouche occupe sa place dès le début**,
  invisible, puis paraît en fondu. L'illustration ne bouge jamais ; en
  contrepartie, le haut de l'écran montre d'abord la couleur du ciel.
- `StatementPopup` : l'énoncé dans le style du cartouche, en plus grand.
- `FamilyIntroCard` : **la carte est la boîte elle-même**, la même
  `FamilyDropZone` grossie et ramenée au centre. En vol, elle ne fait que
  retrouver sa taille et sa place : à l'arrivée, rien ne la distingue de la
  zone qui la remplace. Toute la scène reçoit le toucher, parce que
  l'intitulé déborde du cadre et qu'un enfant ne doit pas manquer sa cible.
- Tous les lieux, à chaque arrivée. L'aperçu du calage la saute.
- **« Le reste » devient « Les autres »**, décision de l'auteur : le nom que
  l'outil donne à la liste du reste d'un tri unique, et les quatre zones de
  l'aventure livrée. Les identifiants livrés restent `le_reste` — un
  identifiant ne suit pas le nom ; une liste neuve naît `les_autres`.
- Les tests d'écran qui portent sur le jeu traversent la mise en place
  (`completeStageIntroduction`, `test/support/`) ; 11 tests d'écran
  l'éprouvent elle-même, jusqu'à l'arrivée exacte de la carte sur la zone.
- **Vue en capture** dans Chromium, pas encore au doigt. 688 tests au vert.

### 0.45.0+65 — 25 septembre 2026 — L'accueil du jeu

**Le jeu s'ouvre sur son accueil**, d'après le croquis de l'auteur : « Les
Aventures de Grisbie » en deux lignes arrondies au-dessus du logo, le logo
découpé en ovale sur un bleu doux, et la roue des aventures dessous — trois
vignettes penchées comme des rayons, chacune avec son titre. Au-delà de
trois aventures, la roue tourne au doigt et boucle ; un toucher ouvre
l'aventure, et sa fin propose « Retour à l'accueil ».

- `HomeLayout` (Dart pur) calcule la mise en page pour un écran donné.
  **L'arc n'est pas centré sur le logo** : centré, il laissait un vide de
  300 points entre le logo et les cartes. Il passe juste sous le logo, courbé
  à 20° par cran, et la hauteur libre se partage en trois. Éprouvé sur six
  formats, du 360×640 au navigateur couché.
- `CurvedTextPainter` pose le titre lettre par lettre sur un cercle.
- `GameHomePage` assemble le tout, sans rien décider.
- `AdventurePage.onFinished` : la fin ramène à l'accueil dans le jeu ; l'outil
  d'auteur, qui n'a pas d'accueil, garde « Recommencer ».
- `defaultAdventureId` a disparu : l'accueil montre tout le sommaire, et
  `startup_test.dart` charge désormais **chaque** aventure proposée.

**Première ouverture réelle du jeu** : construit pour le web et capturé dans
le Chromium sans écran de la session cloud. Piège relevé et noté dans
`Commandes.md` : sans langue, Flutter échoue au démarrage et la page reste
blanche. Rien n'a encore été joué au doigt.

662 tests au vert.

### 0.44.0+64 — 25 septembre 2026 — La vignette d'une aventure

**Chaque aventure a sa vignette**, l'image qui la représente dans la roue de
l'accueil. Décisions de l'auteur : une image propre à l'aventure, au format
des illustrations de narration, **obligatoire** pour jouer.

- `Adventure.coverAsset`, `"cover"` dans le fichier d'aventure. Sans elle,
  `validate()` signale un manque : l'aventure n'est pas complète. Elle fait
  partie de `picturePaths`, donc l'intégration vérifie qu'elle est dans le
  dépôt.
- `CoverFormat` (domaine) : **3:2 en largeur**, 1536 × 1024 conseillé,
  768 × 512 au minimum, 2 % de tolérance. Hors format, l'image sera recadrée
  au centre, et l'outil le dit, dimensions à l'appui.
- **Le défaut corrigé** : `ContentSaver` reconstruisait l'entrée du sommaire
  sans la vignette, et chaque enregistrement l'effaçait — c'est ainsi que
  `cover` avait disparu du sommaire livré. Elle y est désormais recopiée de
  l'aventure, comme le titre.
- Dans l'outil : une carte « Vignette de l'aventure » en tête du parcours,
  qui ouvre `CoverEditorPage` — le sélecteur d'images, les alertes de format,
  et un aperçu recadré comme dans la roue.
- Contenu : « Grisbie va à la plage » prend `pictures/Grisbie_plage.jpg`,
  l'illustration de sa page de garde, **choisie par l'auteur**.
- La roue passe de quatre à trois places : quatre vignettes en largeur ne
  tenaient plus sur un téléphone.

Les aventures fabriquées dans les tests ont reçu une vignette. 599 tests au
vert.

### 0.43.0+63 — 24 septembre 2026 — La roue des aventures, moteur seul

**Premier pas de l'accueil du jeu**, d'après le croquis de l'auteur : le
titre en arche, le logo au centre, et quatre vignettes suspendues sous lui
comme les rayons d'une roue dont le logo serait le moyeu. Le logo ne tourne
pas ; les vignettes, si.

Cette livraison ne pose que le moteur, en Dart pur :

- `AdventureWheel` dit quelle aventure occupe quelle place. Quatre places ;
  à quatre aventures ou moins la roue ne tourne pas et les centre sur l'arc,
  au-delà elle **boucle**. Une place de plus de chaque côté porte celle qui
  entre et celle qui sort, avec sa visibilité. Aucune aventure n'occupe deux
  places à la fois, même à cinq pour quatre places. Au lâcher, `settled`
  cale la roue sur un cran, poussée plus loin par un geste lancé.
- `WheelArc` pose une vignette sur le cercle et l'incline, le haut tourné
  vers le moyeu : droite en bas, penchée en remontant.

**Le logo est déclaré dans `pubspec.yaml`** — poussé sans déclaration, il
faisait échouer `declared_assets_test.dart`.

572 tests au vert.

### 0.42.1+62 — 24 septembre 2026 — L'aventure de l'auteur, et des images qui disent pourquoi

**L'aventure de l'auteur est le contenu livré.** Écrite dans l'outil et
versée par « Intégrer au dépôt » — premier usage réel de l'intégration, qui a
fonctionné. Elle remplace l'aventure inventée. Les tests qui décrivaient
l'ancien contenu (« La rue », l'ancien texte de la gare, le nombre de
fichiers) décrivent désormais celui-ci. Deux tests classaient les mots des
listes entières au lieu de la partie tirée : ils lisent `engine.stage`.

**Vu par l'auteur** : dans l'outil connecté, les vignettes et l'aperçu
n'affichaient pas les images, alors que le jeu les montrait. **Non
reproduit** : le jeu puis l'outil ont été ouverts dans Chromium, compilés pour
le web en release puis en debug, en mode local — images, sélecteur et aperçu
s'affichent. Il reste la connexion au dépôt, qu'on ne peut pas monter ici.
En attendant, **la raison d'un échec s'affiche** (`describeImageError`) dans
l'aperçu et dans chaque vignette, au lieu d'une icône muette ; et les
vignettes remplissent leur case.

548 tests au vert.

### 0.42.0+61 — 24 septembre 2026 — Sept mots par zone

**Vu par l'auteur, dans le jeu** : les zones de « Devant la maison » et de
« La gare » annonçaient la longueur de leur liste. Le compteur disait vrai :
sans `drawCount`, la liste jouait entière.

- **Décision de l'auteur** : sans réglage, chaque zone tire **sept** mots
  (`Stage.defaultDrawCount`). La zone « le reste » aussi, dans l'ensemble de
  ses listes cochées — sept en tout, pas sept par liste.
- **Option A** : une liste de moins de sept mots est à finir, et rend
  l'aventure injouable tant qu'on n'a pas écrit les mots manquants.
- **Contenu livré** : la gare (listes de 2) et la boutique (listes de 6)
  reçoivent le `drawCount` qu'elles jouaient déjà. Sans cela le jeu ne
  s'ouvrait plus, et compléter leurs listes aurait été inventer du
  vocabulaire.
- Les données fabriquées des tests reçoivent de même un réglage explicite ;
  trois tests qui décrivaient l'ancienne règle la décrivent désormais.

547 tests au vert.

### 0.41.0+60 — 24 septembre 2026 — Un seul écran de lecture

**Défaut vu par l'auteur** : les images posées sur les fins ne paraissaient
pas. L'écran de fin n'en affichait aucune — il n'a jamais lu l'illustration.

- **`NarrationPage`** : titre facultatif en haut, illustration à ses
  proportions sur toute la largeur, texte dessous, bouton toujours visible.
  La page de garde et la fin s'en servent toutes deux, au lieu de deux mises
  en page qui divergeaient.
- La fin prend le nom du lieu en titre ; dans l'éditeur, son texte s'appelle
  « Le récit de fin ».
- Premier pas vers la page de récit générale (garde, transition, fin),
  toujours au TODO.

543 tests au vert.

### 0.40.0+59 — 24 septembre 2026 — Listes triées, saisie enchaînée, compte juste

- **Règle retirée par l'auteur** : un mot peut apparaître dans le nom de sa
  famille (« bus » dans « En bus »). `validate()` ne le signale plus.
- **Ordre alphabétique** : `Word.compareAlphabetically`, accents et
  majuscules ignorés ; `WordListBuilder.addWord` insère à sa place,
  `WordListPage` affiche trié. Le repliement des accents passe dans le
  domaine (`foldAccents`), partagé avec les identifiants.
- **Saisie enchaînée** : le curseur revient dans le champ après chaque mot,
  par Entrée comme par le bouton.
- **Défaut vu par l'auteur, dans le jeu comme à l'essai** : une zone annonçait
  la longueur de la liste (« 0 / 12 ») au lieu des mots tirés (« 0 / 7 »), et
  s'ouvrait au septième. `StagePage` prend désormais le compte à la partie
  tirée (`FamilyDropZone.requiredCount`), la place restant celle de l'écran
  pour le calage.

539 tests au vert.

### 0.39.0+58 — 23 septembre 2026 — Intégrer au dépôt

**Publier, c'est verser dans le dépôt.** Depuis Chrome ou Edge, « Intégrer au
dépôt » demande de désigner le dossier `assets/content/` de la copie du dépôt,
et y écrit l'aventure de l'écran avec ses listes et ses mots.

- `ContentIntegrator` : le même `ContentSaver` que l'enregistrement, le
  **dossier du dépôt servant de base** — ses listes et lexiques sont
  complétés là où ils vivent. Seul ce qui change est écrit.
- **Rien ne s'écrit si un contrôle échoue** : `index.json` présent (le bon
  dossier), aventure jouable, chaque image citée dans `pictures/`
  (`Adventure.picturePaths`). Chaque raison est nommée.
- `BrowserContentFolder` : l'accès aux fichiers du navigateur, par import
  conditionnel comme le téléchargement. `ContentStore` (domaine) nomme ce qui
  se lit et s'écrit.
- Le bouton ne paraît qu'où l'on peut désigner un dossier : ni Firefox ni
  Safari.

**Non éprouvé** : compilé pour le web, jamais ouvert dans un navigateur.
532 tests au vert.

### 0.38.0+57 — 23 septembre 2026 — Essayer sur l'appareil

**Le besoin de l'auteur** : créer sur l'ordinateur, vérifier sur le téléphone
avant de publier — seul moyen de savoir si un réglage rend proprement sur un
petit écran.

- **« Essayer ce lieu »**, sur la carte : le vrai écran de jeu, sur le lieu
  seul, jusqu'au premier départ. Offert quand `Stage.canBeTriedAlone` : des
  familles, dont aucune n'est vidée par les mots communs.
- **« Jouer l'aventure »**, en tête du parcours, quand elle est jouable : le
  vrai déroulé du jeu, page de garde comprise.
- Les deux jouent l'aventure **de l'écran**, enregistrée ou non.
  `PreloadedAdventureRepository` passe des tests à `lib/`, et refuse
  désormais une aventure injouable, comme le jeu.

**Écarté** : un marqueur « en test » dans le jeu. Il aurait fallu verser les
brouillons dans le dépôt pour les voir, et recompiler à chaque retouche. Une
aventure est publiée quand elle est dans le dépôt.

Au TODO, décidés pour plus tard : l'écran de choix des aventures, l'aperçu
multi-formats. 521 tests au vert.

### 0.37.0+56 — 23 septembre 2026 — Les images se choisissent dans le dépôt

**Décision de l'auteur** : il verse ses images dans `assets/content/pictures/`
sous le nom qu'il veut, et l'outil les propose. L'outil est compilé à partir
du dépôt, comme le jeu : une image choisie là existe forcément dans le jeu.

- **« Choisir une image »** ouvre `PictureChooserPage` : les images du bundle,
  en vignettes, avec leur nom. `PictureCatalog` (domaine) et
  `BundledPictureCatalog` (manifeste du bundle) les listent.
- **`PictureField`**, un seul champ d'image pour le lieu et la page de garde,
  qui en avaient chacun une copie. Il signale une image citée qui n'est pas
  dans le dépôt : le jeu ne l'afficherait pas.
- **Retirés** : la photothèque de l'appareil (`PicturePicker`,
  `DevicePicturePicker`, `StoredPictureLibrary`, `PictureLibrary`), la copie
  renommée `gare_<horodatage>.jpg`, la mention « image de travail », et la
  dépendance `image_picker`. Sur Android le nom d'origine n'était de toute façon
  pas connu.

Le catalogue lit le vrai bundle en test, noms accentués compris ; aucun
navigateur ne l'a encore fait. 509 tests au vert.

### 0.36.0+55 — 23 septembre 2026 — Le bandeau au-dessus de la scène

**Décision de l'auteur (option A)** : le bandeau des mots est posé au-dessus
de l'illustration, qui occupe ce qu'il laisse. Superposé, il recouvrait la
zone du bus dès qu'un énoncé de deux phrases s'affichait sur un petit
téléphone (22 px sur un 360×640) : le doigt de l'enfant y était arrêté sans
message. Le recouvrement est désormais impossible, quelle que soit la longueur
du texte ; l'image rapetisse d'autant.

**Le calage suit.** Ses poignées étaient placées par un calcul sur l'écran
entier, qui ne savait rien du bandeau : elles auraient été décalées de sa
hauteur. `StagePage.sceneOverlayBuilder` les pose dans la scène même, avec le
rectangle qu'elle a calculé, et `StagePage.interactive` rend l'aperçu inerte.

Trois tests : la scène commence sous le bandeau, même sous un énoncé très
long ; chaque poignée recouvre exactement sa zone de jeu ; l'étape réelle,
munie de l'énoncé que l'auteur a écrit pour la maison, ne recouvre rien sur
trois formats. **Les images de l'auteur** sont arrivées dans
`assets/content/pictures/`. 511 tests au vert.

### 0.35.0+54 — 23 septembre 2026 — L'énoncé sur la scène

**Vu par l'auteur** : le texte d'arrivée saisi dans l'outil ne paraissait pas
sur la page de jeu. Il s'affichait sur un écran de récit intercalé, avant la
scène — or c'est lui qui donne son sens au tri : il pose la question que les
mots tranchent.

- **L'énoncé se lit en haut de la scène**, dans le cartouche des mots, et y
  reste quand ils sont tous classés. `StoryMomentPage` est retiré : un lieu de
  jeu s'ouvre directement sur sa scène.
- **La consigne générique est retirée** (« Pose les mots au bon endroit »).
- L'éditeur de lieu appelle le champ « L'énoncé ». Le calage, qui monte la
  même page, montre l'énoncé réel : l'auteur voit la place qu'il prend.
- La règle « pas d'`onArrival` au lieu de départ quand il y a une page de
  garde » tombe : la page de garde raconte, l'énoncé demande.

**Les trois tolérances héritées sont retirées** (règle du §1 de CLAUDE.md) :
le champ `syllables` n'est plus nettoyé à l'enregistrement, un récit écrit en
simple chaîne n'est plus lu, et une image ne se lit plus que par la source de
contenu — ni `assets/…`, ni adresse `http:` ou `blob:`.

**Défaut mesuré, non corrigé** : sur un 360×640, l'énoncé de deux phrases que
l'auteur a écrit pour la maison fait recouvrir la zone du bus par le bandeau
(22 px). Solution à choisir, voir `TODO.md`. 509 tests au vert.

### 0.34.2+53 — 23 septembre 2026 — Plus de personnage

**Décision de l'auteur** : le personnage était de la dette. Il mêlait deux
choses — quelqu'un qui intervient dans l'histoire, et la mécanique du tri
unique qu'il avait servi à poser. La mécanique vit dans la structure depuis
0.31.0 ; ce qui restait n'était que de la narration.

Retirés : `Character`, `Encounter`, `Stage.encounter` / `isEncounter`,
`ContentIndex.charactersFile`, la lecture de `characters.json` par
`ContentRepository` et sa recopie par `ContentSaver`, l'icône de la carte du
parcours, et la réplique qui remplaçait la consigne sur la scène. Le contenu
livré perd `characters.json` et la réplique de la marchande.

**Aucune compatibilité** : le jeu n'est pas en ligne. La règle est désormais
écrite au §1 de CLAUDE.md, et les tolérances écrites avant elle sont listées
dans `TODO.md`. 508 tests au vert.

### 0.34.1+52 — 23 septembre 2026 — Un lieu rouvert se redéfinit sur place

**Vu par l'auteur, à l'écran** : une fin rouverte depuis sa structure
redevenait *à définir*, et l'écran de structure affichait alors « Choisissez
sur la carte du lieu ce que l'enfant y fait » — sans rien pour le faire. Il
fallait fermer, revenir au parcours, et chercher la carte.

L'écran offre désormais les **trois réponses de la carte** — plusieurs
listes, tri unique, fin —, qui ouvrent la même page de trajets. Il gagne au
passage « Ajouter des trajets » pour un lieu à plusieurs listes, et
« Ajouter la sortie » pour un tri unique qui n'en aurait pas : tout ce que
la carte propose sur la structure, la structure le propose aussi. Trois
tests rejouent le parcours de l'auteur.

512 tests au vert ; les deux points d'entrée compilent pour le web.

### 0.34.0+51 — 23 septembre 2026 — Revenir sur un choix de circuit

**Le manque signalé par l'auteur** : une fois la nature d'un lieu choisie,
rien ne permettait d'y revenir. Le titre de la carte ouvre ce que le lieu
montre, un trajet ouvre sa liste ; la structure elle-même n'avait pas de
geste.

**La ligne de nature devient ce geste.** « Plusieurs listes », « Tri unique »
ou « Fin », sur chaque carte, porte une icône de réglage et ouvre
`StageStructurePage` : changer de nature — plusieurs listes en tri unique en
choisissant le trajet du thème, tri unique en plusieurs listes, l'un ou
l'autre en fin, une fin rouverte —, puis renommer, rediriger ou retirer
chaque trajet. Chaque retrait se confirme en nommant ce qui part. Le TODO
« rouvrir une fin créée par erreur » est soldé.

**Aucun lieu ne disparaît en passant** (choix A de l'auteur). Un lieu que
plus rien n'atteint reste sur le parcours, marqué « Aucun chemin ne mène
ici », et sa carte offre alors « Supprimer ce lieu ». `removeStage` refuse
un lieu encore atteint et le point de départ.

**Tout lieu déjà écrit peut être rejoint**, et plus seulement les fins — à
l'ajout d'un trajet comme en le redirigeant. **Une boucle devient possible,
et elle est signalée** : `Adventure.validate()` nomme chaque trajet d'une
boucle avec une troisième sévérité, `IssueSeverity.warning`, *à vérifier*.
Elle ne bloque ni le jeu ni la mention « jouable » (`ContentIssue.blocksPlay`)
— la spécification n'interdit pas les boucles, et l'auteur a voulu garder le
geste. Un test du domaine utilisait par commodité un lieu menant à lui-même :
c'était une boucle, il a reçu un vrai parcours.

509 tests au vert ; les deux points d'entrée compilent pour le web. Rien n'a
été ouvert sur un appareil.

### 0.33.0+50 — 23 septembre 2026 — Plus d'aide, plus de découpage

**L'auteur retire le système d'indice du jeu.** Jusqu'ici, la première erreur
sur un mot faisait apparaître son découpage en syllabes sous l'étiquette. Un
mot mal placé est désormais refusé, l'étiquette tremble et revient, et
l'enfant réessaie — rien d'autre.

**Le découpage part avec l'aide.** Il n'avait pas d'autre usage, et pesait
dans l'outil : exigé pour tout mot neuf, signalé tant qu'il manquait, porté
par chaque entrée du lexique. Trois voies ont été présentées — tout retirer,
le garder en réserve, le rendre facultatif ; l'auteur a choisi de **tout
retirer**. Une donnée que rien n'utilise finit fausse sans que personne ne le
voie.

- `Word` n'a plus que `text`. `Word.fromJson` ignore `syllables` : un contenu
  écrit avant se lit toujours.
- `Hint`, `HintPolicy` et le compteur d'erreurs de `StageEngine`
  disparaissent ; `PlacementResult` ne dit plus que si le mot est accepté.
- `validate()` ne signale plus de « mot sans découpage ».
- `WordListBuilder` perd la saisie et la correction du découpage ;
  `WordLibrary` ne porte plus que les listes.
- **L'écran de liste n'a plus qu'un champ**, et Entrée ajoute le mot. Au
  passage, il montre enfin l'alerte « un mot apparaît dans le nom de sa
  famille » : elle était filtrée avec les alertes de découpage, qui
  encombraient chaque ligne.
- **Les lexiques livrés sont nettoyés** — champ retiré, mots inchangés. Un
  test vérifie qu'aucun n'en porte plus, et `ContentSaver` retire le champ des
  lexiques qu'il réécrit : ceux déjà déposés sur le dépôt distant se nettoient
  au fil des enregistrements.

La spécification passe en **version de travail 0.9** : « aucune aide à la
lecture » remplace « découpage syllabique comme aide unique » parmi les points
confirmés.

473 tests au vert ; les deux points d'entrée compilent pour le web.

### 0.32.0+49 — 22 septembre 2026 — L'écran de liste

Troisième et dernière livraison convenue pour les listes : l'écran, sur le
moteur posé en 0.31.0. **Toucher un trajet sur sa carte ouvre sa liste.**

Un trajet sans liste propose de **créer** une liste — nommée d'après le trajet,
renommable — ou d'en **réutiliser** une, choisie d'après ses premiers mots. On
tape ensuite un mot et son découpage, séparé par des tirets, des points ou des
espaces ; un mot déjà connu affiche le sien et ne le redemande pas, le lexique
n'en admettant qu'un. Toucher un mot corrige son découpage, partout où il est
cité. Un mot commun à une autre liste du lieu le dit : il ne jouera pas ici.

**Le reste d'un tri unique se compose en cochant des listes** — option C —,
celle du thème exclue puisque ses mots sont précisément ceux que le reste
retire. L'écran rappelle pourquoi ne cocher que des listes sûres.

**Une liste citée ailleurs le dit en tête** : la modifier la modifie partout,
et c'est avant d'y toucher qu'il faut le savoir.

**Chaque trajet dit s'il a de quoi jouer**, sur la carte du lieu : `7/7`,
`3/7`, ou « pas de liste ». C'est la question que l'auteur avait posée, et le
calcul reste dans le domaine (`Stage.supplyOf`), affiché par `SupplySummary`.

**Un défaut évité avant d'exister** : le champ des boîtes de dialogue était
libéré au retour de `showDialog`, alors que la boîte, encore en train de se
refermer, le lisait. Les tests d'écran l'ont attrapé ; la boîte porte
désormais son propre état.

484 tests au vert ; les deux points d'entrée compilent pour le web. **Rien n'a
été ouvert sur un appareil** : c'est le premier point de `TODO.md`.

### 0.31.0+48 — 22 septembre 2026 — Le moteur des listes

Deuxième des trois livraisons convenues pour les listes de mots : tout ce que
l'écran de liste demandera, sans l'écran.

**Tri unique, option C.** L'auteur a retenu la voie du milieu : il choisit la
liste du thème, puis **coche les listes où le jeu peut prendre les mots
« autre »**. Le reste d'un tri unique cite donc plusieurs listes —
`WordFamily.lists`, `"lists"` dans le JSON, `"list"` gardant son sens pour
tout le reste — et le jeu y tire des mots absents du thème. Tirer dans tout le
vocabulaire a été écarté : « banane », absente de « Ce qui se mange » mais
écrite ailleurs, serait refusée à l'enfant qui la range à juste titre.

L'exclusion devient **asymétrique dans un tri unique** : le reste perd les mots
du thème, le thème ne perd rien. `Stage.supplyOf` compte, pour chaque famille,
ses mots, ceux qu'elle perd, ce qui reste et ce qu'on lui demande. La carte
l'affichera ; `validate()` s'en sert déjà.

**`WordListBuilder`**, en Dart pur : créer une liste pour un trajet ou en
réutiliser une, ajouter et retirer des mots, corriger un découpage, renommer,
cocher les listes du reste, et dire où une liste sert. Un mot connu garde son
découpage ; un mot neuf n'entre pas sans le sien. `ContentRepository.loadLibrary`
fournit le lexique et toutes les listes.

**Un trajet naît sans liste.** Chacun recevait une liste vide dont
l'identifiant venait du trajet — `en_bus`. Deux aventures créées dans l'outil
auraient pu s'en disputer un, et la seconde écraser la liste de la première à
l'enregistrement. La règle de l'auteur tranche d'elle-même : il n'y a pas de
mot seul, on crée une liste ou on en réutilise une.

**L'enregistrement écrit les mots et les listes, chacun là où il vit.** Une
liste ou un mot modifié est réécrit dans son fichier d'origine ; ce qui est
neuf va dans `lists/<id>.json` et `lexicon/<id>.json`, déclarés au sommaire. Un
fichier n'est réécrit que s'il change.

**Un défaut corrigé au passage**, trouvé en préparant ce travail : le fichier de
listes propre à l'aventure était réécrit avec les seules listes *nouvelles*.
Au second enregistrement, celles du premier disparaissaient, et les mots
ajoutés à une liste déjà écrite n'étaient jamais enregistrés. Il garde
désormais ce qu'il avait, et trois tests enregistrent deux fois de suite.

463 tests au vert ; les deux points d'entrée compilent pour le web.

### 0.30.0+47 — 22 septembre 2026 — Que fait l'enfant ici ?

**Le défaut signalé** : choisir « Tri unique » en ajoutant des trajets
laissait visible le sélecteur du nombre. Il n'était pas faux — il comptait des
trajets, chacun menant à son propre tri unique — mais il se lisait comme un
nombre de listes, et c'est le modèle qui était en cause. La nature se
choisissait pour le lieu **d'arrivée**, au moment de créer le chemin.

**L'auteur raisonne autrement, et à juste titre** : arrivé à la gare, que fait
l'enfant ? Il range dans plusieurs listes, ou il fait un tri unique, ou c'est
la fin et il n'y a que du texte. La question se pose **au lieu**, sur sa
carte. `StageNature` la lit dans la structure ; un lieu sans famille ni
marqueur de fin est *à définir*, et sa carte propose trois boutons. Tout lieu
créé naît ainsi.

`AdventureBuilder` porte les trois réponses. `addTrips` fait — ou prolonge —
un lieu à plusieurs listes, et ses arrivées naissent à définir.
`defineAsSingleSort` pose ensemble le thème, sa sortie et la liste du reste :
l'un sans l'autre n'est pas un tri unique. `defineAsEnding` clôt le lieu. Les
deux derniers refusent un lieu déjà défini, que redéfinir viderait. `TripKind`
disparaît : un trajet n'a plus de nature. `AddTripsPage` ne fait plus que
nommer les sorties ; pour un tri unique, un seul champ, « Le thème », et aucun
nombre.

**Sept mots par liste** (`AdventureBuilder.defaultDrawCount`), posés sur le
lieu quand il reçoit ses premières listes. Un lieu déjà écrit garde ce qu'il
demandait : le contenu livré ne change pas de comportement.

**« Cette aventure est jouable » ne s'affiche plus que si c'est vrai.**
`ContentReadiness` tire des anomalies trois états — jouable, pas complète,
contient des erreurs —, et l'écran du parcours les annonce en tête.

**La zone manquante est enfin signalée**, *à finir*, mais seulement sur un
lieu illustré. Le jeu refuse toute anomalie, et la gare et la boutique livrées
n'ont ni décor ni zones : les signaler aussi rendrait le jeu impossible à
ouvrir. L'extension est notée dans `TODO.md`.

419 tests au vert ; les deux points d'entrée compilent pour le web.

### 0.29.0+46 — 22 septembre 2026 — Caler les zones sur la vraie image, sans JSON

**Deux défauts vus par l'auteur en ouvrant le calage.** L'illustration du lieu
n'apparaissait pas, et la page affichait un bloc de JSON à copier, alors que
l'enregistrement était devenu automatique.

**L'image manquante était un oubli de transmission.** La page mesurait bien
l'illustration par la source de travail, mais l'aperçu du jeu posé dessous,
`StagePage`, ne recevait aucune source : il cherchait dans le bundle une image
prise avec l'outil, qui n'y est pas, et affichait la couleur de fond. Les
poignées étaient au bon endroit, sur un décor absent. `StagePage.contentSource`
comble le trou ; le jeu, qui ne la passe pas, continue de lire le bundle. Un
test monte le calage sur une source en mémoire et exige que le décor la lise —
retiré, le correctif le fait échouer.

**Le JSON était un vestige.** Il datait du temps où le recopier était la seule
façon d'enregistrer. « Garder » rend l'étape calée à l'éditeur de lieu depuis
0.19.0, et « Enregistrer » l'écrit depuis 0.22.0. Le panneau, « Copier » et
`AreaEditor.export` disparaissent. « Garder » rend désormais les zones
**arrondies au centième** — ce que l'export faisait, et sur quoi porte déjà le
contrôle de chevauchement.

**Autant de zones que de familles.** C'était déjà le cas, et c'est désormais
éprouvé : cinq chemins donnent cinq zones, un tri unique en donne deux, le
thème et le reste. La disposition par défaut passe dans le moteur
(`AreaEditor.defaultLayout`) : trois zones par rangée au plus, sans quoi elles
deviendraient plus étroites qu'un doigt. Les zones posées d'office sont
agrandies à la taille minimale dès que l'illustration est mesurée ; celles que
l'auteur a calées ne sont jamais retouchées sans son geste.

Les chevauchements sont signalés par le **nom** des familles, celui que
l'auteur a saisi, plutôt que par leur identifiant.

**Convenu mais suspendu** : signaler une famille sans zone, qui dans le jeu ne
peut recevoir aucun mot. `loadAdventure` refusant toute anomalie, la gare et la
boutique livrées, qui n'ont pas de zone, rendraient le jeu impossible à ouvrir.
Voir `TODO.md`.

400 tests au vert ; les deux points d'entrée compilent pour le web.

### 0.28.1+45 — 22 septembre 2026 — Les fichiers se demandent ensemble

Ouvrir une aventure depuis le dépôt distant prenait plusieurs secondes, et
l'auteur le voyait. La cause n'était pas le réseau : `ContentRepository`
demandait ses fichiers **un par un**, chacun attendant le précédent. Le
sommaire, puis trois lexiques, puis deux listes, puis les personnages, puis
l'aventure — huit allers-retours en file indienne. Sur un disque c'est
instantané ; à travers un navigateur et un dépôt, les latences s'additionnent.

Seul le sommaire doit arriver d'abord : c'est lui qui dit **quels** fichiers
demander. Tout le reste est indépendant à la lecture, y compris les listes et
le lexique qu'elles citent — une liste ne résout ses mots qu'au moment d'être
*analysée*, pas d'être *lue*. Le chargement part donc en une seule salve, et
l'analyse se fait ensuite dans l'ordre qui convient.

**« En parallèle » est une propriété vérifiée, pas une intention.** Une source
de test compte les lectures en vol simultanément et retient le maximum
atteint : un chargement en file indienne le laisserait à 1. Trois autres
contrôles encadrent le changement — le sommaire arrive bien en premier, le
contenu obtenu est identique à celui d'avant, et rouvrir une aventure ne relit
que son fichier, le reste restant en mémoire.

386 tests au vert, dont 4 nouveaux.

### 0.28.0+44 — 22 septembre 2026 — Une illustration est du contenu

**« Je devrais la trouver quelque part dans Storage, non ? »** La question de
l'auteur désignait le manque exactement : rien n'envoyait jamais d'image.
`ContentSaver` n'écrivait que du JSON, et le pont entre le poste et le
téléphone ne portait donc que du texte. Une photo prise sur le téléphone
n'arrivait jamais sur le poste ; une image choisie dans Chrome n'existait que
dans la mémoire de l'onglet.

**Le principe retenu : une illustration est du contenu.** Elle vit dans le même
arbre que les aventures, part par le même puits et redescendra avec lui. Le
chemin stocké devient `pictures/gare_….jpg`, relatif au dossier du contenu
comme tous les autres, et le contenu livré migre vers
`assets/content/pictures/`.

Trois pièces, et la symétrie du projet les dictait :

- `ContentSink.writeBytes` et `ContentSource.readBytes`, pendants l'un de
  l'autre, sur les cinq implémentations.
- `StoredPictureLibrary` écrit l'image choisie dans l'arbre et rend son chemin.
  `PicturePicker` ne fait qu'ouvrir la photothèque et rendre des **octets** :
  deux rôles séparés, et **tous deux éprouvables sans appareil ni greffon**, ce
  que la version d'avant ne permettait pas.
- `ContentPictureImage`, un `ImageProvider` à part entière qui lit par la
  source. Un `ImageProvider` et non un `FutureBuilder` : c'est ce qui le fait
  entrer dans le cache d'images de Flutter, la source faisant partie de son
  identité — se connecter au dépôt doit bien redonner une autre image.

**L'aperçu vide dans Chrome est réparé par construction**, sans qu'on l'ait
traité pour lui-même. On ne lit plus le chemin rendu par le sélecteur — une
adresse `blob:` que le système révoque aussitôt, d'où `ERR_FILE_NOT_FOUND` — on
lit ses octets et on les écrit. Il n'y a plus de chemin à révoquer.

**Et le code rétrécit.** Deux branches de plateforme disparaissent :
`local_image_provider_io/web`, qui choisissaient entre un fichier et une
adresse, et `picture_keeper_io/web`, ajoutés la version d'avant. Une image se
lit désormais comme n'importe quel fichier de contenu, et « le disque » n'a
plus à avoir un sens différent selon la plateforme.

**Ce que cette version ne prouve pas** : rien de tout cela n'a été exécuté. Le
dépôt d'une image et son aperçu restent à éprouver, dans Chrome comme sur un
téléphone.

382 tests au vert, et les deux points d'entrée compilent pour le web.

### 0.27.0+43 — 22 septembre 2026 — Une panne n'est pas une absence

**Deux défauts, découverts en enregistrant une vraie aventure.** L'auteur a
créé une journée, cliqué « Enregistrer », et ne l'a jamais retrouvée dans la
liste. Les fichiers étaient pourtant bien sur le dépôt distant — la console
Firebase les montrait, horodatés du jour.

**Le premier est de moi, et il est grossier.** Le repli écrit en 0.24.0
attrapait *tout* :

```dart
try { return await preferred.readFile(path); }
catch (_) { return fallback.readFile(path); }
```

Un fichier absent, certes — mais aussi un refus du dépôt, une coupure de
réseau, un blocage du navigateur. Dans tous ces cas il servait silencieusement
le contenu livré. L'écriture réussissait, la lecture échouait, et l'accueil
affichait imperturbablement la liste des assets. Rien ne le disait, et la
lenteur d'ouverture — chaque lecture distante échouant après un délai — était
le seul indice.

D'où `ContentFileNotFound`, qui nomme l'**absence** et elle seule.
`FallbackContentSource` ne se replie plus que sur elle ; tout le reste remonte
et s'affiche. `RemoteContentStore` ne traduit que `object-not-found` — pas
`unauthorized`, qui est un refus de la règle et doit se voir —, et
`FileContentSource` distingue le fichier jamais écrit du dossier interdit.

**Le second est un piège de navigation.** « Garder » ferme un éditeur et rend
son résultat à l'écran du parcours, en mémoire ; seul « Enregistrer » écrit.
C'est la règle voulue. Mais quitter le parcours **jetait tout le travail sans
un mot** : l'écran rendait bien l'aventure modifiée, et l'accueil l'ignorait.
Le parcours demande désormais quoi en faire — rester, quitter sans
enregistrer, ou enregistrer et quitter. Par `PopScope`, pour que le geste de
retour du système passe par là aussi : protéger un seul côté ne protégerait
rien. Et « Enregistrer et quitter » ne sort que si l'écriture a réussi — sortir
après un échec perdrait le travail en croyant l'avoir mis à l'abri.

**Ce que cette version ne répare pas** : la cause première. La lecture depuis
un navigateur est soumise à la politique CORS du bucket, qu'un projet neuf n'a
pas. Ça se règle dans la console Google Cloud, et c'est noté dans `TODO.md`.
Cette version ne fait que rendre la panne visible — ce qui est déjà tout ce
qu'on peut demander à du code.

381 tests au vert, dont 9 nouveaux.

### 0.26.0+42 — 22 septembre 2026 — Charger une image depuis un navigateur

**L'outil n'avait pas de bouton d'image sur le web**, et c'était une décision :
« le navigateur n'a pas de disque où ranger la copie ». Le partage prévu était
la structure au clavier sur un poste, les images sur le téléphone. À l'usage il
ne tient pas — une illustration se charge d'où l'on travaille, et on y travaille
au clavier.

Ce qui l'interdisait n'existait plus vraiment. `image_picker_for_web` est déjà
dans le graphe de dépendances : dans un navigateur, le greffon ouvre le
sélecteur de fichiers du système et rend une adresse `blob:`, que
`contentImageProvider` sait afficher depuis 0.20.0. Le seul morceau qui ne
passait pas le web était la **recopie**, et elle n'y a pas d'objet : ce qu'elle
protège sur un appareil, c'est un fichier de cache qu'Android peut purger.

D'où `picture_keeper_io.dart` / `picture_keeper_web.dart`, choisis à la
compilation comme pour l'affichage d'une image. `DevicePictureLibrary` est
maintenant passée sur toutes les plateformes.

**Ce qui diffère, c'est ce qu'on peut garder, et l'écran le dit.** Sur un
appareil, l'image recopiée se retrouve d'une session à l'autre ; dans un
navigateur, l'adresse `blob:` meurt avec l'onglet. Le taire ferait croire le
travail conservé, et l'auteur ne comprendrait pas de rouvrir son lieu sans
illustration. Le calage, lui, survit : ce sont des fractions rangées dans le
JSON.

La différence est portée par l'interface (`PictureLibrary.keepsPictures`), et
non par un `kIsWeb` consulté dans un widget : l'écran n'a pas à savoir sur quoi
il tourne, et un `kIsWeb` en dur ne s'éprouverait pas — le test qui vérifie la
mention passe une photothèque feinte.

**Ce que cette version ne fait pas** : l'image ne voyage toujours pas.
`ContentSaver` n'écrit que du JSON, et le pont Firebase entre le poste et le
téléphone ne porte donc que le texte. C'est le chantier suivant.

372 tests au vert, et les deux points d'entrée compilent pour le web — seul
contrôle qui valide un import conditionnel.

### 0.25.0+41 — 22 septembre 2026 — Un trajet et son lieu portent deux noms

**L'outil apprenait à l'auteur une règle que le contenu livré dément.** Il
demandait un nom par trajet et en baptisait le lieu d'arrivée : « En bus »
menait donc à un lieu appelé « En bus ». Or ce sont deux choses. « En bus » est
ce que l'enfant lit sur la zone de dépôt ; « La gare » est le lieu où il
arrive, avec son illustration et son récit. C'est même l'intérêt du dispositif :
l'enfant classe des mots sous un moyen, et découvre une destination.

La conséquence la plus visible n'était pas la bonne saisie mais la lecture :
ouvrant « Grisbie va à la plage » dans l'outil, l'auteur a cru à un affichage
cassé — les noms ne correspondaient pas à ce que l'outil lui avait enseigné, au
point de faire passer la seule aventure du jeu pour un contenu bouche-trou.
Conséquence moins visible et plus grave : **l'outil ne savait pas écrire le
contenu livré**, ce qui est le meilleur test qu'on ait de sa complétude.

`NewTrip` porte désormais `name` et `locationName`, et `AddTripsPage` demande
les deux. Le second est proposé d'après le premier et le suit tant qu'on n'y
touche pas — le cas courant, où l'un vaut l'autre, ne coûte donc aucune saisie
de plus. Dès que l'auteur l'écrit, le champ se détache : voir son nom
disparaître en corrigeant une faute de frappe dans le trajet serait
incompréhensible. Le champ disparaît quand le trajet rejoint une fin déjà
écrite : le lieu existe, et le renommer de là changerait son titre à l'insu des
autres chemins qui y mènent.

**L'identifiant du lieu vient du lieu**, désormais, et non du trajet : « La
gare » donne `gare`, exactement ce que le contenu livré écrit à la main.
L'identifiant de la famille, lui, reste celui du trajet (`en_bus`) — elle lui
appartient.

**Et un trajet dit où il mène** : « En bus → La gare » sur sa ligne. La lettre
du lieu suffisait à faire le lien, mais obligeait à descendre chercher sa carte
pour savoir duquel il s'agit ; sur le croquis papier de l'auteur, la flèche
portait les deux bouts. Le nom est tu quand il répète le trajet — « En bus →
En bus » se lirait comme un défaut, et c'est l'état de tout ce que l'outil a
créé jusqu'ici.

371 tests au vert, dont 15 nouveaux, et les deux points d'entrée compilent pour
le web.

### 0.24.0+40 — 22 septembre 2026 — L'outil relit ce qu'il a écrit

**L'outil enregistrait, et rouvrait toujours le contenu livré.** On pouvait
donc écrire une aventure, la déposer, et ne jamais la retrouver : l'écran
d'accueil lisait `AssetContentSource`, or les assets sont scellés au build et
ne contiennent que ce qui a été commité. La boucle est fermée.

`FallbackContentSource` met le travail devant et le contenu livré derrière.
C'est ce qu'il faut des deux côtés : au premier lancement le dossier de travail
est vide et il n'y a que le livré ; après un enregistrement c'est le travail
qui fait foi, y compris quand il n'a réécrit qu'une partie des fichiers — le
lexique qui n'a pas bougé reste lisible. Le repli **ne masque pas** un fichier
écrit illisible : il vaut pour l'absence, jamais pour l'erreur, sans quoi
l'auteur croirait son travail intact.

**Le défaut le plus coûteux était ailleurs, et invisible.** `ContentSaver`
recopie ce que l'outil ne touche pas, dont les *autres* aventures, pour que le
dossier écrit se suffise. Il les lisait dans les assets : enregistrer la gare
ramenait la plage à sa version d'origine, effaçant en silence le travail de la
veille. Il lit maintenant par où l'on écrit.

`AuthorHomePage` reçoit une **fabrique** de dépôt, pas un dépôt. Deux raisons :
`ContentRepository` garde le sommaire et les lexiques en mémoire — c'est ce
qu'il faut pour jouer, pas pour éditer — et **se connecter change la source**,
le sommaire du dépôt distant n'étant pas celui de l'appareil. L'écran rouvre
donc à neuf après un enregistrement comme après un changement de compte. Il
liste les aventures du sommaire et les ouvre par `loadDraft` : une aventure en
cours d'écriture est toujours invalide, et `loadAdventure` la refuserait.

`DeviceContentSink` devient `DeviceContentFolder` et porte les **deux** bouts,
lecture et écriture : écrire sans pouvoir relire est précisément le défaut
qu'on répare. Le dossier est résolu une fois au lancement — lire et écrire
doivent viser le même endroit — et le point d'entrée ne nomme plus ni `dart:io`
ni `path_provider`.

356 tests au vert, dont 10 nouveaux, et les deux points d'entrée compilent pour
le web.

### 0.23.1+39 — 22 septembre 2026 — Un seul projet Firebase, et il existe

Le projet est créé : **`grisbie-43ee9`**. Firebase veut des identifiants uniques
au monde et suffixe les siens ; celui-ci est définitif.

**Il n'y en aura qu'un**, et c'est une décision, pas un raccourci. Deux projets,
dev et prod, étaient prévus depuis 0.9.3. Ce que cette séparation protège
d'ordinaire, ce sont les données réelles des utilisateurs pendant qu'on
expérimente : ici il n'y a **ni utilisateurs ni données**. Le bucket est un
tuyau entre le poste et le téléphone ; la production de ce projet n'est pas
Firebase mais le dépôt git et la fiche Play Store.

Le second coûtait plus qu'il ne protégeait. Chaque lancement porte six valeurs,
et deux jeux de six augmentent surtout le risque de déposer dans le mauvais
bucket. Ce qu'on y perdrait au pire, c'est le travail non encore commité — et
l'outil enregistre aussi en local, donc le bucket n'est jamais la seule copie.
La décision se renverse d'ailleurs pour rien : les valeurs arrivent au
lancement, créer un second projet se résume à changer une ligne de commande.

**La section Firebase de `Noms_et_identifiants.md` était devenue fausse** —
elle décrivait encore le montage par `google-services.json` que 0.23.0 a
supprimé, et un basculement dev/prod « en remplaçant le fichier à la main ».
Elle est réécrite : pourquoi un seul projet, pourquoi des options explicites,
pourquoi l'e-mail plutôt que Google, et ce que les saveurs séparent encore
maintenant qu'elles ne portent plus rien de Firebase.

- `TODO.md` signale ce qui attend au prochain pas : **Cloud Storage réclamera
  sans doute le plan Blaze**, un projet neuf ne provisionnant plus de bucket sur
  Spark depuis fin 2024. La tranche sans frais de Blaze couvre très largement un
  tuyau d'auteur, mais elle demande un moyen de paiement. Si ce passage rebute,
  le contenu étant de petits fichiers JSON, Firestore reste accessible sur Spark
  et seul `RemoteContentStore` serait à réécrire.
- Le nom du bucket est à **relever dans la console**, pas à deviner : il diffère
  selon l'âge du projet.
- Une application **Web** reste à enregistrer, l'outil tournant aussi dans un
  navigateur. L'Android existe déjà.

Aucun changement de code. 346 tests au vert.

### 0.23.0+38 — 22 septembre 2026 — Le dépôt distant

Le pont entre le poste et le téléphone. L'outil dépose le contenu sur Firebase
Storage et le relit, ce qui rend possible le partage voulu : écrire la structure
et les textes au clavier, illustrer sur l'appareil.

**Deux décisions consignées ont été renversées**, et il faut le dire avant le
reste.

**Pas de `google-services.json`.** Le greffon Gradle qui le produit **échoue
quand le fichier manque** : l'appliquer aurait cassé la saveur `jeu`, qui n'a
pas à en avoir. Les valeurs passent donc par `--dart-define` au lancement, et
`Firebase.initializeApp` reçoit des `FirebaseOptions` explicites.

Le gain dépasse le contournement. L'auto-initialisation d'Android — le SDK qui
démarre seul dès qu'il trouve le fichier — **n'existe plus du tout**. Le jeu ne
peut pas contacter Firebase même par mégarde, puisque rien ne l'initialise. Les
saveurs servaient à contenir ce risque ; elles ne portent plus rien de Firebase.
Et rien de secret n'entre dans le dépôt, qui se compile sans aucune de ces
valeurs.

**Connexion par e-mail et mot de passe, pas par Google.** Google sur Android
exige d'enregistrer les empreintes SHA-1 des magasins de clés : ça marche en
debug et ça casse en release, ce qui est le pire moment pour l'apprendre.
L'e-mail se comporte à l'identique sur le web et sur un téléphone, sans greffon
de plus. L'usage est solo, la règle du bucket nomme toujours un UID — que
l'outil affiche une fois connecté, pour qu'on puisse le recopier.

**Le dépôt distant est un dossier comme un autre.** `RemoteContentStore`
implémente `ContentSource` *et* `ContentSink`, avec l'arborescence
d'`assets/content/`. `ContentSaver` et `ContentRepository` n'ont pas bougé d'une
ligne : ils ne savent rien du réseau. C'est le dividende des interfaces posées
en 0.5.0 et 0.22.0.

**Rien n'a été exécuté.** Ni la connexion, ni le dépôt d'un fichier, ni sa
relecture : aucun greffon Firebase ne tourne en session cloud, et le projet
`narya-grisbie-dev` n'existe pas encore. Ce qui est éprouvé ici est la mince
part qui pourrait être fausse **sans** qu'un appareil le dise : la configuration
du lancement et ce qui manque quand elle est incomplète, la traduction des refus
de connexion, l'écran de connexion sur un faux compte. Le reste tient en deux
appels à Firebase.

La marche à suivre en console est réécrite dans `TODO.md` — elle a beaucoup
maigri — et la commande de lancement est dans `Commandes.md`, signalée comme la
seule de ce document qui n'ait jamais abouti.

- `author_only_test.dart` gagne trois contrôles : Firebase n'est importé que par
  `lib/infrastructure/remote/`, `AuthorRemote.connect` ne s'appelle que dans
  `main_author.dart`, et **rien n'initialise Firebase** ailleurs qu'en un seul
  endroit.
- `AuthorAccount` (domaine) est une interface : l'écran de connexion s'éprouve
  sans Firebase, sans réseau et sans compte.
- Où va l'enregistrement se lit sur l'écran d'accueil, une fois, plutôt que
  dans le message qui suit chaque enregistrement : c'est avant de travailler
  qu'on veut le savoir.

346 tests au vert, dont 14 nouveaux. `flutter analyze` sans remarque, et les
deux points d'entrée compilent pour le web.

### 0.22.0+37 — 22 septembre 2026 — Enregistrer

L'outil construisait un parcours, posait des illustrations, écrivait des récits
— et **personne n'écrivait rien**. `OutlinePage` rendait l'aventure modifiée à
l'appelant, qui n'en faisait rien. C'était le trou du chantier ; il est comblé.

**Écrire le seul fichier d'aventure n'aurait pas suffi.** Il ne contient que des
références : sans son sommaire il est introuvable, sans ses listes il en cite
que personne n'a écrites, sans le lexique ses listes citent des mots inconnus.
`ContentSaver` écrit donc l'ensemble, et le contrôle qui compte est le dernier
de son fichier de tests — **le dossier écrit se recharge**, sans rien emprunter
au contenu livré.

Un défaut est apparu à ce contrôle, et c'est lui qui l'a trouvé : le dossier
écrit déclarait les *autres* aventures du sommaire sans contenir leurs fichiers.
Il les recopie désormais. Le défaut ne se serait vu qu'en essayant d'en ouvrir
une.

**Deux modes, et ce n'est pas un réglage de confort.** `includeUnchanged`
recopie ce que l'outil ne touche pas — lexiques, personnages, autres aventures —
pour que le dossier se suffise : c'est ce qu'il faut sur un appareil, qui n'a
rien d'autre. À faux, seul ce qui vient d'être écrit est rendu, ce qui convient
quand la destination possède déjà le reste.

**Deux puits, un par plateforme.** Sur un appareil, un dossier des documents de
l'application (`DeviceContentSink`). Dans un navigateur, le téléchargement
(`BrowserContentSink`, derrière un import conditionnel, avec `web` pour seule
dépendance nouvelle). C'est **le point d'entrée seul** qui choisit : les écrans
ne connaissent qu'un rappel `onSave`, nul quand il n'y a nulle part où écrire.

Le téléchargement est un dépannage, et il se voit : un navigateur ne crée pas de
dossier, chaque fichier descend séparément et son nom porte le chemin aplati
(`adventures_plage.json`). Il faut les reposer à la main dans `assets/content/`.
C'est exactement ce qu'un dépôt distant remplacera.

**Un seul geste écrit, et un seul mot le dit.** Les éditeurs de lieu et de page
de garde disaient « Enregistrer » pour un geste qui ne touchait aucun disque —
ils rendent leur résultat à l'écran du parcours, qui travaille en mémoire. Ils
disent maintenant « Garder », comme le calage le faisait déjà. Deux gestes
portant le même mot laisseraient croire que fermer un lieu suffit à le
conserver.

- `ContentIndex.withAdventure` remplace l'entrée de même identifiant plutôt que
  d'en ajouter une seconde : enregistrer à nouveau est le geste le plus courant.
- `ContentWriter.copyFile` recopie sans relire : charger un lexique pour le
  réécrire ferait courir le risque qu'une sérialisation en perde un champ, et
  c'est justement le fichier que l'outil n'a aucune raison de toucher.
- Le garde-fou de 0.20.0 a attrapé ma propre entorse — `main_author.dart`
  importait `path_provider` directement. Le greffon est reparti dans
  l'infrastructure, et le test nomme désormais deux fichiers.
- **Rien n'a été exécuté sur un appareil ni dans un navigateur.** Les deux
  puits compilent, et le cœur est éprouvé sur un dossier en mémoire ; écrire
  pour de vrai reste à vérifier.

332 tests au vert, dont 18 nouveaux. `flutter analyze` sans remarque, et les
deux points d'entrée compilent pour le web.

### 0.21.0+36 — 22 septembre 2026 — Le web, et ce qu'il fallait démêler pour lui

L'outil d'auteur doit tourner dans Chrome : écrire la structure et les textes au
clavier sur un poste est autrement plus confortable qu'au pouce, et le téléphone
reste pour les images. `web/` est donc ajouté, et **les deux points d'entrée
compilent**.

**Une affirmation de `CLAUDE.md` était fausse**, et je ne l'avais jamais
vérifiée : « builds Android, Web et Windows impossibles ici ». Le build web
fonctionne en session cloud — la chaîne dart2js est fournie avec le SDK, et
seul *ouvrir* un navigateur est impossible. C'est corrigé, et la conséquence est
utile : **`flutter build web` est le seul contrôle qui attrape un `dart:io` mal
placé**. `flutter analyze` et `flutter test` tournent sur la machine virtuelle
Dart, où `dart:io` existe, et ne verraient rien.

**« Le disque » n'a pas le même sens partout.** Un navigateur n'en a pas : ce
qui est un chemin de fichier sur un téléphone y est forcément une adresse — le
blob d'une image choisie, ou demain le fichier déposé sur un stockage distant.
`contentImageProvider` compte donc désormais trois branches : le bundle pour
`assets/`, le réseau pour une adresse, et le disque pour le reste. Cette
dernière est choisie **à la compilation**, par import conditionnel.

**Pas de photothèque dans un navigateur** — `main_author.dart` ne construit
`DevicePictureLibrary` que hors web. L'écran garde son champ de saisie, et c'est
exactement le partage voulu. Le mécanisme existait déjà : `PictureLibrary` était
nullable depuis 0.20.0, et une plateforme sans photothèque était prévue.

**Compiler n'est pas fonctionner**, et rien n'a été ouvert dans un navigateur.
Restent à éprouver, sur le poste : le chargement du contenu depuis les assets,
le glisser-déposer des mots à la souris, et le calage des zones sur grand écran.
C'est dans `TODO.md`.

- `flutter build web` réécrit `analysis_options.yaml` pour y exclure `web/` :
  le fichier suivi porte donc cette ligne, plutôt que de la voir revenir à
  chaque construction.
- Le squelette généré par `flutter create` effaçait la ligne `android` de
  `.metadata` et y ajoutait une ligne iOS. Repris à la main.
- Les deux commandes de construction entrent dans `Commandes.md`, comme le veut
  la règle : elles ont réellement abouti.

314 tests au vert, dont 1 nouveau. `flutter analyze` sans remarque.

### 0.20.0+35 — 21 septembre 2026 — Choisir l'illustration dans l'appareil

L'éditeur de lieu demandait un chemin au clavier. Il ouvre maintenant la
photothèque : **les deux premières dépendances tierces du projet** entrent avec,
`image_picker` et `path_provider`, toutes deux publiées par l'équipe Flutter.

**`image_picker` plutôt qu'un sélecteur de fichiers général**, et pour une
raison qui tient au public : sur Android 13 et au-delà il passe par le Photo
Picker du système, qui **ne demande aucune permission**. L'application ne voit
que l'image choisie.

**Le `pubspec.yaml` étant partagé, ces greffons sont embarqués dans le jeu**,
qui ne les appelle jamais. Ce n'est pas une promesse :
`author_only_test.dart` exige qu'ils ne soient importés que par
`lib/infrastructure/pictures/`, que `DevicePictureLibrary` ne se construise que
dans `main_author.dart`, et que `main.dart` ne mène à aucun écran d'auteur.
Même idée que le test qui interdit `google-services.json` hors de la saveur
auteur : la garantie ne peut pas tenir à la seule bonne volonté.

**L'image choisie est recopiée** (`PictureStore`). Le sélecteur rend un fichier
de **cache**, qu'Android peut purger en cours de session : l'illustration
disparaîtrait sans que rien ne l'explique. Le nom de la copie porte un
horodatage — sans lui, une seconde photo pour le même lieu écrirait au même
chemin, et le cache d'images de Flutter, qui indexe par chemin, continuerait
d'afficher l'ancienne. Le geste paraîtrait sans effet.

**Le découpage suit la règle du projet** : `PictureLibrary` est une interface du
domaine, injectée par constructeur et transmise depuis `main_author.dart` ;
`DevicePictureLibrary` l'implémente dans l'infrastructure. Nulle, le bouton ne
paraît pas et le champ reste saisissable au clavier — les tests passent une
fausse photothèque, et ne touchent ni appareil ni greffon. Le rangement, lui,
ne suppose qu'un disque : il est éprouvé pour de vrai, sur un dossier temporaire.

Une image ainsi prise est **une image de travail**, et l'éditeur le dit sous le
champ : le jeu ne la verra qu'une fois copiée dans `assets/pictures/` et le
contenu recompilé.

**Rien de tout cela n'a été exécuté** — ni `image_picker` ni `path_provider` ne
tournent en session cloud. La vérification sur l'appareil est dans `TODO.md`,
avec le manque qui reste : rapatrier les images de travail dans le dépôt, ce
qui est le même geste que l'enregistrement du contenu.

313 tests au vert, dont 14 nouveaux. `flutter analyze` sans remarque.

### 0.19.1+34 — 21 septembre 2026 — Un lieu ne raconte pas son départ

Correction d'un modèle faux, signalée à l'usage. Une étape avait deux moments
de récit : `onArrival` en entrant, `onCompletion` en repartant. Le second n'a
pas lieu d'être — **l'enfant clique un trajet, et c'est le lieu d'arrivée qui
raconte**, avec son propre texte. La narration appartient à celui qui accueille.

Le contenu livré le démontrait : « Devant la maison » annonçait *« Grisbie est
arrivée à la plage »* au moment où on la quittait, avant que « La plage » ne
raconte la même arrivée à son tour.

`Narrative` perd donc `onCompletion`, et une étape se joue en **deux temps** —
récit puis jeu — au lieu de trois. `_StagePhase.completion` et le
`_pendingDestination` d'`AdventurePage` disparaissent avec.

**Trois textes ont été retirés du contenu livré**, et méritent d'être relus :

| Lieu | Texte perdu |
|---|---|
| `maison` | Grisbie est arrivée à la plage. Une belle journée s'annonce ! |
| `gare` | Le train part dans deux minutes. Vite ! |
| `boutique` | Le sac est plein de bonnes choses. Direction la mer ! |

Le premier faisait doublon avec l'arrivée à la plage. Les deux autres disaient
quelque chose du lieu qu'on quitte ; s'ils doivent revenir, c'est dans le
`onArrival` du lieu suivant, réécrits de son point de vue.

- `Narrative` garde sa forme d'objet pour un seul champ : le concept se nomme,
  le format de contenu ne bouge pas (`"narrative": { "onArrival": … }`), et un
  second moment aurait où se poser le jour où il se justifierait.
- `OutlineBlock.hasTransitionText` devient `hasNarrative` : la case du croquis
  cochait le récit de départ, elle coche maintenant celui d'arrivée.
- `StageEditorPage` perd son champ « En repartant » et **dit pourquoi** sous
  celui qui reste — sans quoi le geste manquant se chercherait.

299 tests au vert. `flutter analyze` sans remarque.

### 0.19.0+33 — 21 septembre 2026 — Ce qu'un lieu porte, et le seuil de la journée

L'écran du parcours disait **où** l'on va. Il dit maintenant aussi **ce qu'il y
a** une fois sur place : cliquer le titre d'une carte ouvre le lieu.

**`StageEditorPage`** — le nom, l'illustration, les zones de dépôt et les deux
moments de récit. Les listes de mots n'y sont pas, et c'est une décision : elles
appartiennent à un **trajet**, pas à un lieu, et une même liste sert à plusieurs
endroits. Les mettre là laisserait croire qu'on les modifie pour ce lieu seul.

Le calage des zones s'ouvre depuis là, sur l'étape **en cours d'édition** —
illustration comprise — et rend l'étape calée. Sans cela l'auteur poserait ses
zones sur l'image d'avant. `AreaEditorPage` gagne donc un bouton « Garder » à
côté de « Copier », qui reste : recoller le JSON à la main est encore la seule
façon d'enregistrer quoi que ce soit.

**La page de garde a sa carte**, au-dessus du premier lieu, plus discrète et
sans lettre : ce n'est pas un point du parcours, rien n'en part. Elle existe
même quand il n'y a pas de page de garde — sans quoi il n'y aurait aucun endroit
où en créer une — et elle se retire, pour ne pas refaire le cul-de-sac signalé
en 0.18.0 avec les fins.

`OpeningEdit` enveloppe le résultat de son éditeur : **renoncer** et **retirer
la page** donneraient tous deux `null`, et ce ne sont pas les mêmes gestes.

**Bundle ou disque : une seule règle.** Les assets sont scellés au build, donc
une image que l'auteur vient d'ajouter sur son téléphone n'y est pas — et
l'édition doit pourtant déjà fonctionner dessus. `contentImageProvider` tranche
sur le préfixe `assets/`, et les **quatre** endroits qui affichaient une image
passent désormais par là : scène de jeu, calage, page de garde, moment de récit.
Deux règles séparées finiraient par diverger, et l'auteur calerait ses zones sur
une image que le jeu ne montre pas.

**Ce qui n'est pas fait, et pourquoi.** L'éditeur demande un chemin **au
clavier**. Choisir le fichier dans l'appareil suppose une dépendance tierce — la
première du projet, partagée par les deux saveurs, donc embarquée dans le jeu
livré aux enfants même s'il ne l'appelle jamais — et ne se teste pas en session
cloud. C'est un arbitrage, pas un oubli : il est posé dans `TODO.md`.

- `Stage.copyWith(clearBackgroundAsset: true)` : `??` garde l'ancienne valeur,
  si bien que retirer une illustration aurait été sans effet et que l'auteur
  aurait cru l'avoir fait.
- `Adventure.withStage` refuse un identifiant inconnu : il ajouterait un lieu
  fantôme au lieu d'en corriger un, et la faute ne se verrait que bien plus
  tard. C'est aussi ce qui tient bon au renommage, l'identifiant ne suivant pas
  le nom.
- `Adventure.withOpening` plutôt qu'un `copyWith`, pour la même raison qu'au
  point précédent : `??` ne saurait pas retirer la page de garde.

299 tests au vert, dont 28 nouveaux. `flutter analyze` sans remarque.

### 0.18.0+32 — 21 septembre 2026 — Une fin est une fin, et elle se partage

Deux remarques d'usage sur l'écran de construction, qui vont ensemble.

**Une fin ne propose plus de trajets.** Sa carte portait « Ajouter des
trajets » comme les autres, ce qui contredisait la ligne du dessus : « Fin de
l'aventure. » La carte reste — il y aura une illustration et un texte d'arrivée
à y poser — mais le bouton disparaît. `AdventureBuilder` continue d'accepter
qu'on prolonge une fin, sans quoi le marqueur et la structure pourraient se
contredire ; c'est l'écran qui ne l'offre plus.

Conséquence assumée, et notée dans `TODO.md` plutôt que passée sous silence :
**une fin créée par erreur ne se rouvre plus depuis cet écran**. Le moteur sait
le faire, il manque le geste — ailleurs que sur cette carte, puisque c'est
précisément là qu'il n'a rien à faire.

**Plusieurs chemins peuvent aboutir à la même fin.** C'est la demande qui
compte : une fin porte un écran, une illustration et un texte, et deux chemins
qui arrivent au même endroit doivent partager la même. Sans cela l'auteur écrit
deux fois la même arrivée, et les deux finissent par différer.

`NewTrip.existingStageId` relie un trajet à un lieu déjà écrit au lieu d'en
créer un. `AddTripsPage` propose les fins existantes (`Adventure.endings`) dès
qu'il y en a — et ne pose pas la question quand il n'y en a aucune, un choix
entre une seule possibilité n'en étant pas un.

- **Le nom saisi reste celui du trajet**, jamais celui du lieu rejoint : c'est
  ce que l'enfant lit sur la zone de dépôt. L'écran le propose par commodité
  quand le champ est vide, faute de quoi « Créer » restait éteint sans qu'on
  voie pourquoi ; il reste modifiable.
- La destination se choisit **trajet par trajet**, contrairement à la nature
  (0.17.1) : d'un même carrefour, un chemin peut rejoindre la plage et l'autre
  finir sur une arrivée qui reste à écrire.
- Le mécanisme vaut pour n'importe quel lieu, pas seulement une fin. L'écran ne
  l'offre que pour les fins : ce sont les seules où la convergence est sûre de
  ne pas créer de boucle, et rien ne demande le reste aujourd'hui.
- `AdventureOutline` gérait déjà une arrivée partagée — elle n'est lettrée
  qu'une fois, et n'a donc qu'une carte. Un commentaire devenu faux depuis
  0.14.0 (« une fin n'y figure pas ») est corrigé au passage.

271 tests au vert, dont 6 nouveaux. `flutter analyze` sans remarque.

### 0.17.1+31 — 21 septembre 2026 — La nature d'un trajet se choisit une fois

L'écran d'ajout posait la nature **trajet par trajet** : sous chaque nom, les
trois pavés d'explication revenaient. Demander trois directions affichait donc
neuf choix, et permettait de composer un lot bigarré — une fin, un tri unique et
un tri à plusieurs listes — sans qu'on sache plus ce qu'on demandait.

La nature passe **en tête, et vaut pour tout le lot** ; le nombre vient ensuite.
C'est l'ordre des questions : la nature décide de la mécanique du lieu d'arrivée,
le nombre n'est qu'une commodité de saisie.

**L'interdiction de mélanger porte sur un ajout, pas sur un lieu.** « Devant la
maison » ouvre sur un tri à plusieurs listes et sur deux fins : l'aventure livrée
mélange déjà les natures, et l'outil doit pouvoir la reproduire. L'écran énonce
donc la règle et son contournement — revenir ajouter les autres ensuite, ce à
quoi sert le rappel « partent déjà d'ici ».

**Et « une seule sortie » porte sur l'arrivée, pas sur le départ.** Ouvrir
plusieurs tris uniques depuis un même carrefour est légitime : chacun a sa
propre liste du reste. Le bridage inverse subsiste, et lui seul — ajouter
*depuis* un tri unique n'admet qu'un trajet. Deux points que les commentaires et
un nouveau test distinguent désormais, la confusion étant facile.

265 tests au vert, dont 2 nouveaux. `flutter analyze` sans remarque.

### 0.17.0+30 — 21 septembre 2026 — Des listes plus grandes que la partie

Une idée de conception qui renverse une règle écrite : **une liste de mots est
réutilisable et plus grande que ce qu'une partie en montre**. À l'entrée d'un
lieu, le moteur en tire quelques mots, après avoir retiré ceux que la liste
partage avec ses voisines. Rejouer la même journée ne redonne donc plus les
mêmes mots.

**La règle du mot ambigu n'est pas abandonnée, elle change de main.** Jusqu'ici
un mot présent dans deux familles du même lieu était une *faute d'auteur*, que
`validate()` signalait comme fausse — la version 0.4.1 avait retiré onze mots
partagés entre « En bus » et « En voiture », à la main. Désormais
`Stage.drawnWith` les retranche des deux côtés avant le tirage. Le résultat à
l'écran est identique — aucun mot dans deux familles — mais il est garanti au
lieu d'être surveillé. Écrire le même mot dans deux listes devient même la façon
de déclarer qu'il est ambigu *ici* : ailleurs, sans la liste voisine, il joue.

La machine ne prend en charge que la moitié facile : elle ne voit que
l'orthographe. `klaxon` écrit dans la seule liste « voiture », alors qu'un bus en
a un, sera toujours proposé et refusé à tort. Le champ lexical disjoint reste un
travail d'auteur, et le format le dit.

**Ce que `validate()` signale désormais, c'est le manque que l'exclusion
laisse.** Pas assez de mots pour le nombre demandé est *incomplet* — le remède
est d'en écrire d'autres, ce qui est le geste normal de l'écriture. Une liste
entièrement absorbée par ses voisines est *faux* — les deux disent la même chose,
et continuer d'écrire n'y changera rien. L'exclusion se calculant lieu par lieu,
« assez de mots » n'est jamais une propriété de la liste seule : la même liste
tient ici et manque là, selon ses voisines.

**Un troisième objet, entre le lexique et la famille.** `WordList` (`id`, `name`,
mots) est ce qui manquait : le lexique définit chaque mot une seule fois et
refuse le doublon, alors qu'un mot doit pouvoir appartenir à plusieurs thèmes ;
une famille porte un nom affiché, une destination et une zone, toutes choses
propres à un lieu. Une famille **cite** désormais une liste (`"list": "bus"`) au
lieu de porter ses mots. Les listes vivent dans `assets/content/lists/`, annoncées
par le sommaire comme les lexiques.

- `Stage.drawCount` donne le nombre de mots tirés par famille, `WordFamily.drawCount`
  le remplace : les listes n'ont pas à être de la même taille d'un thème à l'autre.
  Nul des deux côtés, la liste joue entière — d'où un contenu livré **au
  comportement inchangé**, ses sept familles migrées mot pour mot.
- À ne pas confondre avec `visibleWordCount`, qui compte les étiquettes à l'écran
  et non les mots d'une famille.
- Le tirage se fait dans `StageEngine`, avec le `Random` injecté : l'interface n'a
  pas à connaître une règle de jeu, et les tests restent reproductibles.
- `ContentWriter.writeWordLists` complète la symétrie lecture/écriture, avec le
  même contrôle champ par champ : une aventure enregistrée sans ses listes
  citerait des listes que personne n'a écrites.
- Deux tests qui encodaient l'ancienne règle ont été réécrits plutôt que
  supprimés : ils disent maintenant ce qui reste faux quand deux listes se
  recouvrent entièrement.
- C'est le tri unique qui y gagne le plus. Une seule liste d'objets hétéroclites
  peut servir tous les tris uniques du jeu, chacun en retranchant son thème —
  exactement le danger que la règle « jamais tirés au hasard » voulait éviter.

263 tests au vert, dont 23 nouveaux. `flutter analyze` sans remarque.

### 0.16.0+29 — 21 septembre 2026 — Un troisième choix, et des listes bien à soi

Deux remarques d'usage, dont une qui demandait d'abord une vérification.

**« La liste du reste est-elle globale ? »** Non — mais la crainte était
justifiée dans la lettre. Les listes appartiennent au lieu ; seuls les **mots**
sont globaux, définis une fois dans le lexique et cités ensuite. Sauf que la
famille était construite en `const`, et Dart canonise les constantes : deux tris
uniques partageaient **littéralement le même objet**. Immutable, donc rien
n'aurait jamais divergé — mais il ne faut pas avoir à le démontrer pour être
tranquille. Le `const` tombe, et deux tests le prouvent : les familles ne sont
pas le même objet, et remplir l'une laisse l'autre intacte.

**Un troisième choix structurel : « Une fin ».** À côté du tri à plusieurs
listes et du tri unique, `TripKind.ending` crée un lieu **déjà achevé** — le seul
qu'on puisse créer terminé, ni faux ni incomplet. Il manquait : rien ne
permettait de clore une journée depuis l'outil.

Les trois choix quittent le bouton segmenté pour une liste à trois entrées, où
chacune **dit en une ligne ce que l'enfant y fera**. Ce ne sont pas trois façons
d'habiller un lieu, ce sont trois mécaniques ; un contrôle qui les réduit à des
étiquettes courtes le cachait.

- `RadioListTile` avait changé d'API : les deux avertissements de dépréciation
  sont traités par un `RadioGroup`, pas laissés en place.
- Le plan de navigation discuté — cliquer le titre pour l'image et les zones,
  cliquer un trajet pour sa liste de mots, un bouton « Valider » — est consigné
  dans `TODO.md`. Il absorbe les étapes 4 à 6 du chantier, et reste à arbitrer.

- 240 tests au vert, dont 7 nouveaux.

### 0.15.0+28 — 21 septembre 2026 — Le tri unique

Essayé sur l'appareil, le mode « personnage » affichait un trajet **« sans
issue »** — un mot qui se lit comme une panne, alors que cette liste est la
moitié du dispositif. Le défaut d'affichage en cachait un plus profond : le
nom.

**Ce que la boutique de la gare fait n'est pas une rencontre, c'est une autre
mécanique de lecture.** Au lieu de trier entre plusieurs familles homogènes,
l'enfant trie entre **une liste et son complément** : ce qui est du thème, et
tout le reste. Dans un tri à trois familles, il compare les mots entre eux et
le choix se réduit à mesure — remplir une catégorie est en soi une aide. Ici il
n'y a rien à comparer : chaque mot se juge seul contre un seul critère. C'est
plus abstrait, et plus difficile.

Le personnage n'était qu'un habillage posé dessus. Il devient ce qu'il est :
**un ornement**, qu'on pose sur n'importe quel lieu, et dont aucune mécanique
ne dépend. L'outil n'en invente plus.

- `Stage.isSingleSort` : une famille **sans destination** est la liste du
  reste, et sa présence suffit à dire la mécanique. Rien de déclaré, comme le
  veut la règle du projet.
- Corollaire, et `validate()` le refuse : **un tri unique n'a qu'une seule
  sortie**. Deux en feraient un tri ordinaire affublé d'une liste de rebut, ce
  qui n'est plus la même chose. L'écran n'en propose donc pas davantage, et le
  moteur le garantit.
- `TripKind.encounter` devient `TripKind.singleSort`. Le bouton dit
  « Plusieurs listes » ou « Tri unique », et explique ce qui attend l'enfant
  là-bas.
- « sans issue » devient **« le reste »**, et le lieu annonce sa mécanique.
- La liste du reste est toujours posée d'office — c'est la moitié du
  dispositif, et il n'y aurait aucun moyen de la deviner ensuite.

Un manque disparaît au passage : l'outil ne fabriquant plus de `Character`,
`ContentWriter` n'a plus à savoir écrire `characters.json`.

`CLAUDE.md` et `Format_fichier_aventure.md` portaient l'ancienne définition —
« une étape portant un `character` est une rencontre ». Les deux sont repris :
c'est une décision qu'on renverse, elle doit se lire. La spécification, elle, ne
décrivait pas cette mécanique du tout ; elle gagne la ligne qui lui manquait,
puisque le cadrage fonctionnel fait foi.

- 233 tests au vert, dont 10 nouveaux.

### 0.14.0+27 — 21 septembre 2026 — Toute arrivée devient une carte

Essayé sur l'appareil, l'écran de 0.13.0 s'est révélé inutilisable, et pour une
raison que je n'avais pas vue : **je n'affichais que les lieux ayant déjà des
trajets**. Or un lieu qu'on vient de créer n'en a aucun. Ajouter trois
directions ne faisait donc rien apparaître en dessous, et il devenait impossible
de les prolonger — précisément ce que l'écran existe pour faire.

Corrigé à la racine, dans `AdventureOutline` : **tout lieu a son bloc**, avec ou
sans trajet, fin comprise. Chaque arrivée devient donc une carte plus bas, avec
sa lettre et son propre bouton. Un lieu sans trajet le dit (« Aucun trajet ne
part d'ici pour l'instant »), une fin l'annonce, et l'un comme l'autre proposent
de prolonger la journée.

Deuxième correction, du même défaut d'usage : **la page d'ajout rappelle ce qui
part déjà du point**. Elle s'ouvrait vide sur un lieu qui avait trois
directions, et laissait croire qu'elles avaient disparu.

**Créer une aventure à partir de rien** : `AdventureBuilder.createAdventure`
et `NewAdventurePage` — un titre, un lieu de départ, deux champs. L'aventure
neuve est incomplète et jamais fausse, et se construit ensuite de proche en
proche. Accessible depuis le sommaire de l'outil d'auteur.

- La section « Lieux non reliés » disparaît : elle faisait doublon avec les
  cartes. Un lieu que rien n'atteint le dit désormais sur la sienne.
- Piège consigné : un `ListView` ne construit que les cartes visibles. Sur la
  fenêtre de test par défaut, les lieux du bas n'existent pas dans l'arbre et
  les recherches échouent **sans que rien ne soit cassé**. Les tests d'écran
  agrandissent donc la fenêtre.

Rien n'est toujours enregistré : c'est le manque suivant, et le plus criant
maintenant qu'on peut créer une journée entière.

- 223 tests au vert, dont 9 nouveaux.

### 0.13.0+26 — 21 septembre 2026 — L'écran de construction du parcours

L'outil d'auteur sait désormais bâtir une journée. Un point porte sa lettre, ses
trajets se lisent dessous, et un bouton **Ajouter** demande combien de trajets
en partent, leur nature — classique ou personnage — et leur nom. Ce qui est
construit apparaît en dessous avec son lettrage, et cliquer un trajet ajoute la
suite depuis son arrivée.

**`AdventureBuilder`** (Dart pur) porte la règle tranchée avec l'auteur :
*l'identifiant naît du nom, puis s'en détache*. « La gare » donne `gare` — on
retire l'article de tête et les accents —, puis l'identifiant cesse de suivre le
nom. Un identifiant qui suivrait casserait, à chaque renommage, toutes les
destinations qui le citent, et le nom du fichier d'illustration avec.

La règle reproduit d'ailleurs exactement les identifiants que l'auteur écrivait
déjà à la main : `gare`, `garage`, `plage`, `maison`. Les accents tombent parce
qu'un identifiant finit dans un chemin de fichier — `arret`, `marche`, `foret`
restent lisibles.

- Un homonyme est **suffixé, jamais écrasé** : deux « La gare » donnent `gare`
  et `gare_2`.
- Un trajet **de type personnage** pose d'office le classeur de rebut que la
  spécification exige. Sans cela le lieu naîtrait à moitié, et il faudrait y
  penser à chaque fois. Son intitulé reste provisoire — comment nommer ce second
  classeur est une question ouverte du `TODO`.
- Ajouter un trajet à une fin **la fait cesser d'en être une**, sinon le
  marqueur et la structure se contrediraient.
- Un lieu neuf naît **incomplet et jamais faux** : écrire ne produit pas d'écran
  rouge, ce qui était tout l'objet de la distinction posée en 0.10.0.
- `Stage.families` prend une valeur par défaut vide : un lieu qu'on vient de
  poser est un état légitime depuis que la fin se déclare.

**Ce qui n'est pas fait, et qu'il faut savoir** : l'écran travaille **en
mémoire** et rend l'aventure modifiée à l'appelant. Rien ne l'enregistre. Trois
manques sont consignés dans `TODO.md` — l'enregistrement, l'écriture de
`characters.json` qu'un trajet personnage suppose, et le passage de
`loadAdventure` à `loadDraft` dans l'outil, sans lequel une aventure devenue
incomplète ne se rouvrirait plus.

- 214 tests au vert, dont 22 nouveaux.

### 0.12.0+25 — 21 septembre 2026 — Le lettrage du croquis

`AdventureOutline` calcule le repérage `A`, `B1`, `C2` du croquis papier de
l'auteur, et la liste des points qui se déploient, dans l'ordre où on les lit.

La règle de lettrage ne se devine pas, et c'est le croquis qui l'a donnée : `B1`
donne `C1, C2` tandis que `B2` donne `D1, D2`. **La lettre ne marque pas la
profondeur** — chaque point qui se déploie consomme la lettre suivante pour le
groupe de ses arrivées. Un test la fige sur l'arbre exact de la photo.

**Le lettrage ne se stocke jamais.** Il se recalcule, et il bouge : insérer un
trajet avant un autre fait passer `B2` en `B3`. Excellent repérage à l'écran,
très mauvais identifiant — les identifiants restent français, explicites et
choisis par l'auteur.

Ce qu'il encaisse, parce qu'un brouillon n'est jamais propre :

- une destination annoncée **avant** que son lieu existe : le trajet s'affiche,
  sans flèche d'arrivée ;
- un lieu atteint par **deux chemins** : une seule lettre, les deux trajets la
  citent ;
- un **classeur sans issue** — le « garde-le » d'une rencontre : visible, mais
  n'ouvrant rien ;
- un lieu **qu'aucun chemin n'atteint** : montré à part plutôt que disparu, sans
  quoi un lieu créé puis oublié serait impossible à relier ;
- un **cycle**, qui ne fait pas tourner le rendu sans fin ;
- **plus de vingt-six groupes**, où les lettres se doublent en `AA`, `AB` —
  deux groupes homonymes rendraient deux lieux indiscernables.

Dart pur, dans `lib/application/`. Rien n'est encore affiché : c'est le calcul
que l'écran de construction consommera.

Décision prise en chemin : **le parseur de notation ne sera pas écrit.** L'auteur
construira son parcours par boutons plutôt qu'en collant du texte, et un langage
dont personne ne se sert est un langage à maintenir pour rien. Seul le rendu —
ce lettrage — avait un emploi.

- 192 tests au vert, dont 15 nouveaux.

### 0.11.0+24 — 21 septembre 2026 — Une fin se déclare

Le croquis d'une aventure sur papier portait une ligne que le format ne savait
pas exprimer : `F1, G1, H1 → Fin`.

Jusqu'ici, une étape sans famille était terminale, et c'était tout. Mais une
étape **qu'on vient de créer et qu'on n'a pas encore écrite** n'en a pas non
plus. Les deux étaient indiscernables : un lieu posé puis oublié passait pour
une fin, et `validate()` n'avait rien à dire.

`Stage.isEnding` — `"ending": true` dans le JSON — lève l'ambiguïté. Le getter
dérivé `isTerminal` disparaît : une seule notion, déclarée.

C'est une information en double avec la structure, ce que le projet proscrit
ailleurs et continue de proscrire pour les rencontres. Elle est acceptée ici à
une condition, qui est tout l'intérêt : la redondance est **vérifiable**. Une
fin qui porte des familles est *fausse* — les mots classés ouvriraient un chemin
depuis une fin. Un lieu sans famille qui ne se déclare pas fin est *incomplet*.
Les deux ne peuvent donc pas mentir l'un sur l'autre en silence.

- Les trois lieux terminaux du contenu livré — `rue`, `garage`, `plage` — sont
  marqués.
- Le contrôle a immédiatement attrapé le fixture des tests de chargement, dont
  l'étape d'arrivée ne se déclarait pas fin. C'est exactement son office.
- `CLAUDE.md` et `Format_fichier_aventure.md` consignent l'exception **et sa
  justification** : une décision qu'on renverse doit se lire, pas se découvrir.

- 177 tests au vert, dont 3 nouveaux.

### 0.10.0+23 — 21 septembre 2026 — Faux, ou seulement incomplet

Début de l'étape 3 du chantier, par le moteur. L'outil d'auteur doit signaler
les erreurs « en direct », et c'est là qu'une difficulté apparaît : **une
aventure en cours d'écriture est toujours invalide**. Le premier lieu créé n'a
pas de mots, aucune famille ne mène nulle part, le lieu qu'on vient d'ajouter
n'est relié à rien. Afficher `validate()` tel quel donnerait un écran rouge
permanent, que l'auteur apprendrait à ignorer en trois minutes — et le jour où
une vraie faute s'y glisserait, elle passerait inaperçue.

`validate()` ne renvoie donc plus des chaînes mais des `ContentIssue`, chacune
portant sa nature et l'endroit où corriger : étape, famille, mot.

**Faux** — un mot ambigu entre deux familles, un mot présent dans le nom de sa
famille, une zone qui déborde ou qui en chevauche une autre, un lieu de départ
introuvable. Rien de tout cela ne s'arrange en continuant d'écrire.

**Incomplet** — une famille sans mots, un mot sans découpage, un lieu dont
aucune famille ne mène encore ailleurs, un lieu que rien ne relie, et **une
destination annoncée avant que son lieu existe**. Cette dernière est un choix :
écrire « le bus va au marché » puis créer le marché est une façon normale
d'avancer, et une promesse pas encore tenue est de toute façon indiscernable
d'une faute de frappe. Les traiter en faute interdirait d'écrire le parcours
dans l'ordre où il se raconte.

Le classement vit dans le domaine, jamais dans l'interface : décider qu'un mot
ambigu est une faute alors qu'une famille vide ne l'est pas est un jugement sur
le contenu, pas une question d'affichage.

Conséquence découverte en chemin : `loadAdventure` **refuse** une aventure
présentant la moindre anomalie. C'est le bon contrat pour le jeu — une aventure
incomplète est injouable, et mieux vaut un message clair qu'une partie bloquée
devant l'enfant. Mais avec ce seul chemin, l'outil d'auteur n'aurait jamais pu
rouvrir ce qu'il venait d'enregistrer. D'où `ContentRepository.loadDraft`, qui
charge sans opposer `validate()` — et lève ce seul contrôle : un fichier absent
du sommaire ou illisible y échoue comme ailleurs.

Rien de tout cela n'est visible pour l'instant : l'interface de l'étape 3 reste
à écrire.

- 174 tests au vert, dont 16 nouveaux.

### 0.9.6+22 — 21 septembre 2026 — Les commandes ont un document

**Les deux saveurs se construisent et se lancent sur le poste.** Le montage
Android tient, et ce qui n'était qu'une configuration plausible devient un fait.

D'où ce document : `docs/Commandes.md`, ce que l'on tape pour lancer et vérifier.
Règle d'écriture reprise de `CLAUDE.md` — **une commande n'y entre que le jour où
elle a réellement été exécutée avec succès**. Rien sur la construction d'un
paquet publiable ni sur la signature : ces gestes n'ont jamais été faits.

Chaque commande est donnée avec ce qu'elle exige et ce qu'elle produit. Une
commande sans son contexte finit recopiée au mauvais endroit — et ici, la moitié
d'entre elles ne tournent pas en session cloud.

Le reste de la version est du dégroupage. La section « Construire » de
`Noms_et_identifiants.md`, le README de `src/auteur/` et un commentaire de
`build.gradle.kts` portaient chacun leur copie des deux commandes de lancement.
Trois descriptions du même geste, promises à diverger. Elles renvoient désormais
au document, qui est seul à les décrire. `Noms_et_identifiants.md` redevient ce
qu'il doit être : une table de vérité, pas un manuel.

- 158 tests au vert, inchangés — rien de fonctionnel n'a bougé.

### 0.9.5+21 — 21 septembre 2026 — Les saveurs configurent enfin

Le premier vrai build des saveurs, sur le poste de développement, s'est arrêté
avant même de compiler :

```
Product Flavor jeu contains custom resource values, but the feature is disabled.
```

Les libellés sous l'icône étaient écrits en `resValue()` dans
`build.gradle.kts`. **AGP 9 désactive cette fonctionnalité par défaut**, et
refuse de configurer le projet quand une saveur s'en sert.

Deux corrections possibles : rallumer le drapeau
(`buildFeatures { resValues = true }`), ou ne plus en dépendre. La seconde est
retenue. AGP éteint ces fonctionnalités implicites l'une après l'autre au fil
des versions, tandis que le recouvrement de ressources par saveur est le
mécanisme Android le plus ancien et le plus stable qui soit. Et un libellé
d'application **est** une ressource : sa place est dans `res/values/`.

- `android/app/src/jeu/res/values/strings.xml` et son équivalent pour la saveur
  auteur portent `app_name` — « Grisbie » et « Grisbie auteur ».
- Le test lit désormais ces deux fichiers, et **refuse tout `resValue(`** dans le
  fichier de build : la panne ne peut pas revenir par distraction.

Cette version corrige la précédente, et rien d'autre. Elle illustre la limite
annoncée en 0.9.4 : un test qui lit des fichiers ne remplace pas un build. Il
avait bien vérifié que les libellés existaient, pas que Gradle accepterait la
façon de les produire.

- 158 tests au vert.

### 0.9.4+20 — 21 septembre 2026 — Deux saveurs Android

La version précédente interdisait `google-services.json` partout, faute de
pouvoir le ranger quelque part. Deux saveurs Gradle lui donnent enfin une place,
et une seule.

`jeu` et `auteur`, dans la dimension `usage`. La saveur auteur porte le suffixe
`applicationIdSuffix = ".auteur"` : l'outil devient un autre paquet Android, les
deux applications cohabitent sur le téléphone de l'auteur, et **un jeu construit
par erreur avec la saveur auteur ne porte pas l'identifiant publié** — il est
impubliable, donc l'erreur est sans conséquence. C'est la raison de ce suffixe,
plus que la cohabitation.

Conséquence à reporter en console : l'application Android s'enregistre dans les
deux projets Firebase sous `fr.naryabordeaux.grisbie.auteur`, jamais sous
l'identifiant du jeu, qui n'existe ainsi dans aucun projet.

- `android/app/src/auteur/` est le seul emplacement autorisé pour
  `google-services.json`, et le test le refuse ailleurs en nommant le fichier
  égaré. Un README y explique ce qu'on y dépose et pourquoi.
- Le fichier passe dans `.gitignore`, à tout emplacement : le dépôt est destiné à
  l'open source et ce fichier porte les clés du projet de l'auteur. Revirement
  assumé par rapport à 0.9.3 — l'argument d'alors (« ignoré, il serait présent au
  build sans que rien ne le signale ») ne tient pas : le test lit le disque et non
  l'index de git, un fichier ignoré mais présent le fait échouer tout autant.
- Le libellé sous l'icône quitte le manifeste pour les saveurs
  (`android:label="@string/app_name"`) : « Grisbie » et « Grisbie auteur ». Deux
  icônes portant le même nom auraient été indiscernables.
- **Une saveur Gradle ne choisit pas le point d'entrée Dart** : `--flavor` et
  `-t` sont indépendants. `main_author.dart` vérifie donc `appFlavor` au
  démarrage et refuse la saveur du jeu, où il n'aurait pas sa configuration
  Firebase et aurait échoué plus tard et plus loin. Le suffixe couvre l'autre
  sens.
- Les saveurs rendent `--flavor` obligatoire pour tout build. `flutter analyze`
  et `flutter test` ne passent pas par Gradle et restent inchangés.

**Ce qui n'est pas prouvé** : le test lit des fichiers, il ne lance pas Gradle.
Il attrape un nom qui dérive, une saveur mal écrite, un fichier égaré ; il ne dit
rien de la compilation. Aucun build Android n'étant possible en session cloud, le
premier vrai build se fera sur le poste.

- 158 tests au vert.

### 0.9.3+19 — 21 septembre 2026 — Le jeu prend son nom

Le projet s'appelait encore `reading_game` partout où il ne s'affichait pas, et
`reading_game` était aussi ce qui se serait affiché sous l'icône. Quatre
orthographes du même jeu cohabitaient : le package Dart, l'identifiant Android,
le libellé du manifeste et le titre de l'application.

Tout passe à **Grisbie**. Le moment n'est pas indifférent : l'`applicationId`
Android devient définitif à la première publication sur le Play Store, une autre
valeur serait ensuite une autre application, sans ses installations ni ses avis.

- Package Dart `reading_game` → `grisbie`, dans les 35 fichiers qui l'importent.
  `ReadingGameApp` devient `GrisbieApp`.
- Android : `applicationId` et `namespace` en `fr.naryabordeaux.grisbie`, paquet
  Kotlin déplacé, `android:label` à « Grisbie » — le modèle Flutter y avait
  laissé `reading_game`.
- `UiStringsFr.appTitle` en « Les Aventures de Grisbie », et la description
  générée du `pubspec.yaml` enfin remplacée.
- **Signature de la version publiée** câblée par `android/key.properties`, avec
  son modèle commenté. Ni la clé ni ses mots de passe n'entrent dans le dépôt ;
  fichier absent, le build retombe sur la clé de debug.
- `docs/Noms_et_identifiants.md` : la table de vérité des noms, les quatre
  couches à ne pas confondre, Firebase et la signature.
- **`android_packaging_test.dart`** contrôle ce que l'application annoncera une
  fois publiée — identifiant, namespace, paquet Kotlin, libellé. Aucun code Dart
  ne lit ces valeurs, et aucun build Android n'est possible en session cloud :
  rien d'autre ne les regardait.
- Le même test **interdit tout `google-services.json` dans `android/`**. Sur
  Android, le SDK Firebase s'initialise seul dès que ce fichier est présent ; les
  deux points d'entrée partageant le dossier `android/`, le jeu livré aux enfants
  l'embarquerait. Volontairement pas mis dans `.gitignore` : ignoré, il serait
  présent au build sans que rien ne le signale.
- Décision consignée : le produit Firebase retenu est **Cloud Storage**, pas
  Firestore. Projets `narya-grisbie-dev` et `narya-grisbie-prod`.
- 155 tests au vert.

### 0.9.2+18 — 21 septembre 2026 — Écrire sur un vrai disque

Deuxième étape de l'outil de création. La précédente travaillait en mémoire et
ne voyait donc ni les chemins, ni les dossiers absents, ni ce que le jeu ferait
du fichier écrit.

`FileContentSink` enregistre dans un dossier et crée les répertoires manquants —
un dossier vierge n'a ni `adventures/` ni `lexicon/`, et la première aventure
d'une installation neuve aurait échoué sans cela. `FileContentSource` fait la
lecture correspondante : les assets étant scellés au moment du build, l'outil ne
peut pas relire par eux ce qu'il vient d'enregistrer.

Le test qui compte écrit l'aventure dans un dossier temporaire puis la recharge
avec le `ContentRepository` du jeu, et retrouve les mêmes étapes et les mêmes
zones. C'est la chaîne entière — sérialisation, chemins, système de fichiers,
chargement — et non plus seulement sa moitié.

`ContentWriter` sait aussi écrire le fichier père : une aventure que le sommaire
n'annonce pas est introuvable pour le jeu, donc en créer une suppose toujours de
le réécrire.

Au passage, le `DiskContentSource` des tests s'appuie sur `FileContentSource` au
lieu d'en être une seconde version.

**Décision de cette session** : le contenu créé transitera par Firebase Storage,
en tuyau d'auteur uniquement — le jeu livré reste hors ligne et ne contacte rien.
Storage n'étant qu'une arborescence de fichiers, le dépôt distant se branchera
par une autre implémentation de `ContentSink`, sans toucher à `ContentWriter`.
Rien de Firebase n'est encore dans le dépôt : l'intégration n'est pas testable en
session cloud, faute de SDK Android.

150 tests au vert.

### 0.9.1+17 — 21 septembre 2026 — Écrire le contenu, sans rien perdre

Première étape vers un outil qui crée une journée entière au lieu de copier des
coordonnées. Avant toute interface, il fallait la garantie que l'écriture est
fidèle : un outil qui enregistre en perdant un champ abîme le contenu sans que
rien ne le signale.

`ContentSink` est le pendant de `ContentSource` — abstrait pour la même raison,
écrire doit s'éprouver sans Flutter ni appareil. `ContentWriter` réécrit une
aventure en s'appuyant sur les `toJson()` que le jeu utilise déjà : le format
n'est décrit qu'une fois, sinon la description écrite finirait par diverger de
celle qui est lue.

Le test central compare le fichier écrit au fichier livré, champ par champ, et
nomme le chemin de ce qui manque — `/stages[0]/backgroundColor`. La comparaison
est volontairement asymétrique : l'écriture explicite les valeurs par défaut
qu'un auteur avait laissées implicites, ce qui est sans gravité ; c'est la
disparition d'un champ qui serait grave. Vérifié en retirant pour de bon
`backgroundColor` de la sérialisation, le test tombe en le nommant.

Deux autres garanties : réécrire deux fois donne le même fichier, sinon ouvrir
puis fermer l'outil sans rien changer laisserait une différence dans git ; et le
JSON est indenté et terminé par un saut de ligne, le contenu devant rester
relisible par un enseignant ou un parent.

Rien ne s'en sert encore. C'est le socle, posé et éprouvé avant de construire
dessus.

144 tests au vert.

### 0.9.0+16 — 21 septembre 2026 — Outil de calage des zones

Poser les zones de dépôt sur une illustration demandait d'ouvrir l'image dans
un éditeur, de relever des pixels et de diviser à la main. Six décors restent à
traiter, trois zones chacun : une soixantaine de divisions, chacune une
occasion de se tromper d'un chiffre.

`lib/main_author.dart` est un second point d'entrée — sous Android Studio,
« Run 'main_author.dart' » au lieu de `main.dart`. Il affiche l'étape réelle en
aperçu inerte, décor et bandeau des mots compris, et pose par-dessus des
poignées de déplacement et de redimensionnement. « Copier » met le JSON dans le
presse-papiers. Le jeu livré aux enfants n'en contient aucune trace : ni bouton
caché, ni geste secret à découvrir par mégarde.

Voir le bandeau réel est le point : une zone posée trop haut passe dessous, et
le doigt y est intercepté avant d'atteindre la cible, sans aucun message. La
mesure a d'ailleurs surpris — la contrainte est la plus forte sur les écrans
**les moins** allongés, où l'illustration occupe toute la hauteur : 14,3 % de
bande perdue sur une tablette, 11 % sur un petit téléphone, rien sur un
téléphone allongé où le bandeau flotte dans le ciel. D'où la règle consignée
dans le format : `top` jamais en dessous de 0,15 pour une image en 2:3.

`AreaEditor` porte toute la géométrie, en Dart pur : contrainte aux bords,
taille minimale de 48 points — la cible qu'un doigt d'enfant peut viser —,
arrondi au centième, et chevauchement jugé sur les valeurs **arrondies**, celles
qui seront réellement écrites. Un détail vérifié par un test : arrondir `left`
et `width` séparément peut faire dépasser leur somme, et le jeu refuserait
alors de charger ce que l'auteur vient d'exporter.

`BackgroundImageSize` est extrait de `SceneLayout` pour que la scène de jeu et
l'outil partagent une seule résolution d'image. Deux versions finiraient par
diverger, et l'auteur calerait ses zones sur une géométrie qui n'est pas celle
du jeu.

**Un bug de démarrage découvert au passage** : `main.dart` demandait encore
`grisbie_beach` après le renommage de 0.8.0. Le jeu n'aurait pas démarré sur
l'appareil, avec la suite entièrement verte — aucun test ne lance `main.dart`.
C'est la quatrième fois que ce motif se présente dans ce projet. L'identifiant
est désormais public et `test/infrastructure/startup_test.dart` vérifie qu'il
existe dans `index.json` et que son aventure se charge.

140 tests au vert.

### 0.8.0+15 — 21 septembre 2026 — Contenu en français, le mot est sa propre clé

Le jeu apprend à lire le français, mais son lexique s'écrivait en anglais :
« arrêt » s'appelait `bus_stop`, « essence » `fuel`, et il avait fallu inventer
`garage_word` parce que `garage` servait déjà de nom de lieu. Cette indirection
sert à traduire une interface — or il n'y a rien à traduire ici, le contenu
**est** la langue du jeu.

`Word` n'a donc plus d'identifiant : son `text` le désigne partout, dans le
lexique comme dans les aventures. Une famille s'écrit maintenant
`"words": ["arrêt", "ticket", "horaire"]`, lisible d'un coup d'œil par un
enseignant ou un parent. Les identifiants d'étapes, de familles et de
personnages passent eux aussi en français (`maison`, `en_bus`, `marchande`).
Seuls les noms de champs JSON restent en anglais, puisqu'ils portent
directement les champs Dart.

Conséquence assumée : deux mots de même orthographe ne peuvent plus coexister.
Ils ne le pouvaient déjà pas en pratique — l'enfant ne voit que l'orthographe et
n'aurait pas pu les distinguer. Le contrôle de doublon existant gagne au change :
il détectait des clés techniques en double, il détecte désormais des **mots** en
double, et nomme le fautif.

Le découpage syllabique suit les sons et non les lettres, règle pédagogique
retenue contre la syllabation graphique académique : `["a", "rê"]` pour
« arrêt ». Le test qui exigeait que les syllabes reconstituent le mot est donc
retiré — il interdisait précisément les découpages recherchés. Seule l'absence
de découpage reste signalée ; l'orthographe et le son cohabitent à l'écran, le
mot sur l'étiquette et son découpage juste en dessous.

Fichiers renommés au passage : `adventures/grisbie_plage.json`,
`lexicon/nourriture.json`, `lexicon/lieux.json`.

119 tests au vert.

### 0.7.1+14 — 20 septembre 2026 — Plus d'écran de texte redondant au départ

La page de garde annonçait « Grisbie part à la plage », et l'écran suivant le
répétait sur fond estompé : deux écrans de texte d'affilée avant de jouer, dont
le second n'apprenait rien.

Le lieu de départ n'a donc plus de `narrative.onArrival` — le format le
permettait déjà, ce champ étant facultatif. Après « C'est parti ! », le jeu
commence directement. Le récit de départ de ce lieu est conservé et reformulé,
pour ne plus faire écho au bouton.

Les autres lieux gardent leur récit d'arrivée : la gare et la boutique ne
répètent rien.

Un test vérifie que le lieu de départ n'a pas de récit d'arrivée tant qu'une
page de garde existe, et le conseil est consigné dans
`docs/Format_fichier_aventure.md`.

119 tests au vert.

### 0.7.0+13 — 20 septembre 2026 — Page de garde d'une aventure

Une aventure peut désormais s'ouvrir sur un écran d'accueil : un titre en haut,
une illustration en pleine largeur, le texte dessous.

Ce n'est pas une étape — il n'y a rien à classer — mais la page de garde de la
journée qui commence. Elle appartient donc à l'aventure (`Adventure.opening`) et
non à un lieu. Sa mise en page diffère volontairement des moments de récit :
c'est un seuil que l'on franchit une fois, pas une transition entre deux lieux.

- `AdventureOpening` : `title` (facultatif, celui de l'aventure sert de repli),
  `image` (facultative), `text`.
- `AdventureOpeningPage` : titre, image **entière et à ses proportions** — elle
  peut donc être horizontale, à l'inverse des décors de jeu —, texte, et bouton
  « C'est parti ! » maintenu hors du défilement pour rester à portée du pouce.
- « Recommencer » repasse par la page de garde : refaire le voyage, c'est le
  refaire depuis le début.

**Un piège de test rencontré au passage.** Le test d'enchaînement tournait sans
fin — sept minutes avant d'être interrompu. En cause : `testWidgets` fait
tourner une **horloge simulée**, où une lecture de fichier réelle ne se résout
jamais. Charger le contenu dans `setUpAll` règle le problème, et
`PreloadedAdventureRepository` sert l'aventure déjà en mémoire. Le test passe
maintenant en une seconde. La règle est consignée dans `CLAUDE.md`.

118 tests au vert.

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
