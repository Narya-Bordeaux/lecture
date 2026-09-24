# CLAUDE.md — Jeu de découverte de la lecture

> Ce document ne décrit que ce qui existe réellement dans le dépôt.
> Une section n'est ajoutée que le jour où son objet est créé. Ne jamais y
> décrire une intention : les intentions vont dans `docs/TODO.md`.

## 1. Projet

Jeu numérique de découverte de la lecture pour enfants de 6 à 7 ans. L'enfant lit
des mots et les classe dans des familles de sens, au fil d'un parcours illustré.

Le cadrage fonctionnel fait foi : `docs/Specification_jeu_decouverte_lecture.md`.
Ne pas inventer de règle de jeu absente de la spécification — les points non tranchés
y sont listés explicitement comme ouverts.

**Et ne jamais inventer de contenu pédagogique.** Lieux, trajets, mots,
découpages, récits : c'est un travail d'auteur, et lui seul. Du vocabulaire
inventé qui a l'air plausible est **pire que pas de vocabulaire du tout** — il
passe les contrôles, s'installe dans le dépôt et se fait oublier, jusqu'au jour
où un enfant le lit. Quand du contenu manque pour éprouver quelque chose,
fabriquer des données **dans les tests**, jamais dans `assets/content/`. C'est
arrivé : tout ce qui suit « Devant la maison » dans l'aventure livrée avait été
inventé de cette façon, et l'auteur ne l'a découvert qu'en ouvrant l'outil. Il
a été remplacé en 0.42.1 par l'aventure que l'auteur a écrite dans l'outil et
intégrée au dépôt.

**Version actuelle : 0.42.1+62** — le niveau test est jouable : moteur, contenu et
interface de l'étape de départ. Une seule aventure existe, et la progression
n'est pas encore enregistrée. Un outil d'auteur existe sur un second point
d'entrée (`lib/main_author.dart`) : il cale les zones de dépôt sur l'illustration
réelle. Le chantier en cours l'étend à la création d'une journée entière, voir
`docs/current.md`.

**Le jeu n'est pas en ligne, et aucune compatibilité ne se construit.** Aucune
version n'a été publiée, aucun joueur n'a de progression ni de contenu à
préserver. Quand le modèle ou le format change, on change le contenu du dépôt
avec lui — jamais de lecture tolérante d'une forme ancienne, de conversion
automatique, ni de champ gardé « pour ne pas casser ». Ce code-là se paie
toujours, et ici il ne protège personne. Les tolérances écrites avant cette
règle ont été retirées en 0.35.0.

**Plateformes visées** : Web, Android, Windows. iOS et macOS ne sont pas visés — le
dossier `ios/` a été supprimé en 0.1.1, voir `docs/TODO.md` pour le régénérer.
`android/` et `web/` sont configurés ; Windows reste à ajouter.

**Le web sert d'abord l'outil d'auteur** : écrire la structure et les textes au
clavier sur un poste, garder le téléphone pour les images. Les deux points
d'entrée compilent pour le web, **mais aucun n'a jamais été ouvert dans un
navigateur** — compiler n'est pas fonctionner. Voir `docs/TODO.md`.

**Noms et identifiants** : la table de vérité est
`docs/Noms_et_identifiants.md`, contrôlée par
`test/infrastructure/android_packaging_test.dart`. Le jeu s'appelle **Grisbie**
sous l'icône, « Les Aventures de Grisbie » sur la fiche Play Store, et
`fr.naryabordeaux.grisbie` pour Android — **cet identifiant sera définitif dès la
première publication**. Le package Dart est `grisbie`. Ne renommer aucun de ces
éléments sans reprendre le document.

**Cinq dépendances tierces** — `path_provider` (équipe Flutter), `web`
(équipe Dart), `firebase_core`, `firebase_storage` et `firebase_auth`. Elles
ne servent qu'à l'outil d'auteur : savoir où écrire, rendre les fichiers par
le téléchargement d'un navigateur, écrire dans le dossier du dépôt désigné
dans Chrome, et déposer le contenu sur le dépôt distant. `image_picker` a été retiré en 0.37.0 : les images se choisissent
dans le dépôt, plus dans l'appareil.
Le `pubspec.yaml` étant partagé, **elles sont embarquées dans le jeu**, qui ne
les appelle jamais. Ce n'est pas une promesse, c'est vérifié :
`test/infrastructure/author_only_test.dart` exige que les greffons ne soient
importés que par l'infrastructure dédiée, qu'aucun code n'ouvre plus la
photothèque de l'appareil, qu'`AuthorRemote` ne se construise que dans
`main_author.dart`, que **rien n'initialise Firebase** hors de
`author_remote.dart`, et que `main.dart` ne mène à aucun écran d'auteur.

**Pas de serveur** : aucune donnée ne quitte l'appareil. La progression est stockée
localement. Le public étant mineur, toute proposition d'ajout d'un backend, d'un
compte ou d'une télémétrie doit être posée à l'utilisateur, jamais introduite d'office.

**Firebase ne s'initialise jamais tout seul** — et c'est le point structurant.
Le montage d'abord prévu passait par `google-services.json`, qu'Android lit au
démarrage sans qu'on le lui demande : les saveurs servaient à contenir ce
risque. Il a été écarté en 0.23.0 pour deux raisons. Le greffon Gradle qui
produit ce fichier **échoue quand il manque**, ce qui aurait cassé la saveur
`jeu`. Et des `FirebaseOptions` explicites suppriment l'auto-initialisation :
le jeu **ne peut pas** contacter Firebase, même par mégarde, puisque rien ne
l'initialise. `author_only_test.dart` le vérifie. Les valeurs arrivent par
`--dart-define` au lancement (`docs/Commandes.md`) : rien dans le dépôt, rien à
ignorer par git, et le projet se compile sans elles.

**La connexion se fait par e-mail et mot de passe**, pas par Google. Google sur
Android exige d'enregistrer les empreintes SHA-1 des magasins de clés — ça
marche en debug et ça casse en release. L'e-mail se comporte à l'identique sur
le web et sur un téléphone, sans greffon de plus. L'usage est solo : un compte
créé à la main dans la console, et la règle du bucket nomme son UID, que l'outil
affiche une fois connecté.

**Deux saveurs Android**, `jeu` et `auteur` — la saveur auteur porte le suffixe
`.auteur`, ce qui fait cohabiter les deux applications sur le téléphone et rend
impubliable un jeu construit par erreur avec elle. Elles ne portent plus rien de
Firebase depuis 0.23.0. **Une saveur ne choisit pas le point d'entrée Dart** :
`--flavor` et `-t` s'apparient à la main, voir `docs/Noms_et_identifiants.md`.

## 2. Environnement

- `flutter` / `dart` : **disponibles** — Flutter 3.47.5 / Dart 3.13.4, installés dans
  `/opt/flutter` par le hook de démarrage de session
  (`.claude/hooks/session-start.sh`). Le PATH est déjà positionné ; au besoin :
  `export PATH="/opt/flutter/bin:$PATH"`. L'avertissement « running as root » est
  inoffensif.
- `node` : disponible (v22).
- **Le build web fonctionne ici** — `flutter build web` compile les deux points
  d'entrée, la chaîne dart2js étant fournie avec le SDK. C'est la seule
  plateforme qu'on puisse construire en session cloud, et **le seul contrôle
  qui attrape un `dart:io` mal placé**. En revanche rien ne peut être *ouvert* :
  pas de navigateur.
- **Builds Android et Windows impossibles ici** : ni SDK Android, ni toolchain
  Windows.

Commandes de vérification, à lancer après toute modification de code :

```bash
flutter analyze
flutter test
```

Elles ne passent pas par Gradle et ignorent donc les saveurs. **Toutes les
commandes du projet sont dans `docs/Commandes.md`** — notamment celles de
lancement, qui exigent `--flavor` et ne tournent que sur un poste équipé.

La version du SDK est épinglée dans le hook. Pour en changer, mettre à jour
ensemble `FLUTTER_VERSION` et `FLUTTER_ARCHIVE_SHA256`, dont l'empreinte se trouve
dans `releases_linux.json` publié par Flutter.

## 3. Lire en premier

`docs/current.md` — état courant, version, travail en cours. À lire explicitement
au début de chaque session (aucun hook ne l'injecte pour l'instant).
- Même sujet que la session précédente → continuer. Sujet différent → réinitialiser.
- **Si le contexte a été compacté (session longue) : relire ce fichier.**
- **Mettre à jour en fin de session** : version, ce qui vient d'être fait, chantier
  ouvert ou fermé.

`docs/versions.md` — historique des versions **et procédure de versioning
obligatoire**. La lire avant tout changement de version. Toute session livrant une
fonctionnalité ou une correction donne lieu à un incrément de version.

`docs/TODO.md` — backlog, liste unique et courte de ce qui reste à faire.

## 4. Séparation moteur / interface

C'est la règle structurante du projet. Le moteur de jeu doit pouvoir tourner, et
surtout être testé, **sans Flutter** : même logique réutilisable dans un autre
contexte, et traitement des données homogène.

| Dossier | Contenu | Peut importer Flutter |
|---|---|---|
| `lib/domain/` | Modèles métier et règles pures : mot, famille, étape, niveau, parcours | **Non** |
| `lib/application/` | Moteur de jeu et état : sélection des mots, validation d'un classement, politique d'aides, progression | **Non** |
| `lib/infrastructure/` | Technique : chargement du contenu, persistance locale de la progression | Toléré si nécessaire |
| `lib/ui/` | Affichage et interactions | Oui |

**Convention vérifiable** — aucun fichier de `lib/domain/` ou `lib/application/` ne
contient `import 'package:flutter/`. Contrôle :

```bash
grep -rn "package:flutter/" lib/domain lib/application && echo "VIOLATION" || echo "OK"
```

Corollaire pratique : les tests du moteur sont des tests Dart purs, sans
`WidgetTester` ni `pumpWidget`.

## 5. Conventions vérifiables

**TDD** — le développement se fait test d'abord. Un comportement du moteur s'écrit
en test avant d'être implémenté.

**Imports** — toujours `package:grisbie/` ; jamais de chemins relatifs :

```dart
// ✅
import 'package:grisbie/domain/models/word.dart';
// ❌
import '../../domain/models/word.dart';
```

**Nommage** — commentaires en français ; symboles (variables, méthodes, classes) en
anglais et explicites.

**Immutabilité** — les modèles sont immutables (`final`). Modification via
`copyWith()`, jamais de mutation directe.

**Sérialisation** — chaque modèle chargé depuis le contenu ou persisté implémente
`toJson()` et `fromJson()`.

**Injection de dépendances** — toujours par constructeur ; pas de singleton appelé
directement dans la logique métier. En particulier, le moteur reçoit sa source de
contenu et sa persistance, il ne les construit pas.

**Aléa** — jamais de `Random()` construit dans la logique de jeu : injecter un
`Random` (graine fixée en test). Sans cela le tirage des mots n'est pas testable.

**Chaînes d'interface** — centralisées dans `lib/ui/strings/ui_strings_fr.dart`.
À ne pas confondre avec le contenu pédagogique, voir §6.

**Grep avant de créer** — chercher si un widget, service ou modèle similaire existe
déjà avant d'en créer un nouveau.

## 6. Contenu pédagogique

Les mots, familles, niveaux et textes d'histoire sont **des données, pas du code**.
Ils vivent dans `assets/content/` en JSON et sont chargés par `lib/infrastructure/`.

**Le format est spécifié dans `docs/Format_fichier_aventure.md`** — structure des
quatre sortes de fichiers, champs, contrôles automatiques. Le lire avant de
toucher au contenu, et le mettre à jour si le format change.

Quatre fichiers, un rôle chacun : `index.json` dit ce qui existe, `lexicon/*.json`
définit chaque mot **une seule fois**, `lists/*.json` regroupe les mots par thème,
et `adventures/*.json` assemble le tout
par références. **`pictures/` s'y ajoute** : une illustration est du contenu, et
tout chemin d'image s'écrit relatif à `assets/content/` — `pictures/gare.jpg`,
jamais `assets/pictures/gare.jpg`. Un mot n'est défini qu'une fois ; le
chargement refuse le doublon.

**Trois objets, trois questions** — et c'est ce qui justifie le troisième :
`Word` dans le lexique dit **qu'un mot existe, et comment il s'écrit**, `WordList`
dit **de quoi il parle**, `WordFamily` dit **où cette liste se pose dans ce lieu**,
sous quel nom et vers quelle sortie. Le lexique refuse le doublon, et pourtant un
mot doit pouvoir appartenir à plusieurs thèmes ; une famille porte un nom affiché,
une destination et une zone, toutes choses propres à un lieu. Il manquait l'objet
du milieu. Une famille **cite** une liste (`"list": "bus"`), elle ne porte pas ses
mots.

**Tout le contenu est en français, identifiants compris** — ids d'étapes, de
familles, de listes. Le jeu n'a pas vocation à être traduit, et une clé
technique anglaise n'ajoutait qu'un détour : il fallait savoir qu'« arrêt »
s'appelait `bus_stop` pour l'employer. Seuls les noms de champs JSON restent en
anglais, puisqu'ils portent directement les champs Dart.

**L'identifiant naît du nom, puis s'en détache** — `AdventureBuilder.slugify`
tire `gare` de « La gare », en retirant l'article de tête et les accents. La
règle reproduit les identifiants que l'auteur écrivait déjà à la main, et les
accents tombent parce qu'un identifiant finit dans un nom de fichier. Une fois
créé, il **cesse de suivre le nom** : renommer un lieu ne le touche pas. Un
identifiant qui suivrait casserait, à chaque renommage, toutes les destinations
qui le citent.

**Un mot est désigné par son orthographe.** `Word` n'a pas d'identifiant : son
`text` est sa clé, dans le lexique comme dans les aventures. Conséquence assumée,
deux mots de même orthographe ne peuvent coexister — ils seraient de toute façon
indiscernables à l'écran. Le chargement refuse le doublon en nommant le mot.

Raison : le contenu doit pouvoir évoluer sans recompilation, être relu par un
enseignant ou un parent, et le dépôt étant destiné à l'open source, c'est le point
d'entrée le plus accessible pour une contribution extérieure.

**Lire et écrire sont symétriques** — `ContentSource` lit, `ContentSink` écrit,
et `ContentWriter` enregistre via les `toJson()` que le jeu utilise déjà : le
format n'est décrit qu'une fois. Les assets étant **scellés au build**, aucune
implémentation ne peut réécrire `assets/` ; l'outil d'auteur passe donc par
`FileContentSink`, et relit par `FileContentSource`.
`test/infrastructure/content_writer_test.dart` compare le fichier écrit au
fichier livré champ par champ et nomme ce qui manque — une sérialisation qui
oublierait un champ ferait disparaître du contenu en silence.

**Faux ou seulement incomplet** — `validate()` ne renvoie pas des chaînes mais
des `ContentIssue`, chacune portant une `IssueSeverity` et l'endroit où corriger
(étape, famille, mot). Une aventure en cours d'écriture est *toujours* invalide :
tout signaler de la même façon donnerait à l'outil d'auteur un écran d'alerte
permanent, qu'on apprendrait à ignorer. Le classement vit dans le domaine, jamais
dans l'interface — décider qu'un mot ambigu est une faute alors qu'une famille
vide ne l'est pas est un jugement sur le contenu. Détail dans
`docs/Format_fichier_aventure.md` §6.

**Les fichiers se demandent ensemble** — `ContentRepository` ne lit le
sommaire seul que parce qu'il dit *quels* fichiers demander ; tout le reste
part en une salve (`Future.wait`). Les listes et le lexique qu'elles citent en
font partie : une liste ne résout ses mots qu'à l'**analyse**, pas à la
lecture. Un par un, c'étaient huit allers-retours en file indienne —
instantané sur un disque, plusieurs secondes depuis un dépôt distant.
`test/infrastructure/parallel_loading_test.dart` compte les lectures
simultanées : en file indienne, le maximum resterait à 1.

**Le jeu refuse, l'outil tolère** — `ContentRepository.loadAdventure` échoue dès
la moindre anomalie, et c'est le bon contrat : une aventure incomplète est
injouable. `loadDraft` charge la même aventure sans opposer `validate()`, et
c'est le seul contrôle qu'il lève — un fichier absent du sommaire ou illisible
échoue là comme ailleurs.

Ne jamais coder en dur une liste de mots dans un widget ou dans le moteur.

**Le mot ambigu n'est plus interdit, il est retiré** — la règle n'a pas disparu,
elle a changé de main. `Stage.drawnWith` retranche de chaque liste les mots
qu'elle partage avec les autres listes du **même lieu**, avant le tirage : un mot
ambigu ne peut donc plus arriver à l'écran, ce que la vigilance de l'auteur ne
garantissait pas. Écrire le même mot dans deux listes devient la façon de
déclarer qu'il est ambigu *ici* ; ailleurs, sans la liste voisine, il joue.

La machine ne prend en charge que la moitié facile : elle ne voit que
l'orthographe. `klaxon` écrit dans la seule liste « voiture », alors qu'un bus en
a un, sera proposé et refusé à l'enfant qui le classe au bus. Le champ lexical
disjoint reste un travail d'auteur (voir plus bas).

Ce que `validate()` signale, c'est désormais le **manque** que l'exclusion
laisse : pas assez de mots pour le `drawCount` demandé est *incomplet* — il faut
en écrire d'autres ; une liste entièrement absorbée par ses voisines est *faux* —
les deux disent la même chose. L'exclusion se calculant lieu par lieu, « assez de
mots » n'est jamais une propriété de la liste seule.

Une règle issue de la spécification, à respecter dans les données comme dans le
moteur : compléter une famille **ouvre** sa destination sans y envoyer l'enfant.
Plusieurs destinations peuvent être ouvertes à la fois ; seul un départ explicite
termine l'étape.

**Un mot n'est que son orthographe** — `Word` n'a qu'un champ, `text`. Il
portait son découpage en syllabes, qui ne servait qu'à l'aide affichée après
une erreur ; l'aide retirée (0.33.0), la donnée est partie avec elle : une
donnée que rien n'utilise finit fausse sans que personne ne le voie.

**Un mot peut apparaître dans le nom de sa famille** (« bus » dans « En
bus ») — la règle qui l'interdisait a été **retirée par l'auteur** en 0.40.0 :
le mot se devine, et ce n'est pas grave. `validate()` ne le signale plus.

**Une liste est rangée par ordre alphabétique** — `Word.compareAlphabetically`,
l'ordre d'un lecteur français : les accents et les majuscules ne déplacent pas
un mot (« école » avec les « e »). `WordListBuilder.addWord` insère le mot à
sa place, si bien que le fichier se trie à mesure qu'on l'écrit, et
`WordListPage` affiche la liste triée quel que soit l'ordre du fichier. Le
repliement des accents (`foldAccents`, `lib/domain/text/`) est le même que
celui des identifiants : une seule table.

**Décor et zones** — l'illustration d'une étape (`backgroundAsset`) et l'endroit de
chaque zone de dépôt (`WordFamily.area`) sont aussi du contenu. Les zones sont
repérées en fractions de l'image, jamais en pixels, pour rester collées au décor
quelle que soit la taille de l'écran.

Ces fractions ne s'écrivent pas à la main : `lib/main_author.dart` est un
**second point d'entrée**, l'outil de calage. Il monte l'étape réelle en aperçu
inerte — décor, bandeau, cadres — et pose par-dessus des poignées de
déplacement, une par famille : une par chemin dans un lieu ordinaire, deux
dans un tri unique (le thème et le reste). **Aucun JSON n'est montré** — le
recopier a longtemps été la seule façon d'enregistrer ; « Garder » rend
désormais l'étape calée, arrondie au centième, à l'éditeur de lieu, et
« Enregistrer » l'écrit avec le reste. L'aperçu lit le décor **par la source
de travail** (`StagePage.contentSource`) : sans quoi il cherchait dans le bundle
une image prise avec l'outil, et l'auteur calait sur un fond vide. **Les
poignées se posent dans la scène du jeu**, par `StagePage.sceneOverlayBuilder`,
qui leur passe le rectangle de l'illustration tel que la scène l'a calculé :
le bandeau grandit avec l'énoncé et repousse l'image, et un second calcul sur
l'écran entier décalait les poignées d'autant. L'aperçu est rendu inerte par
`StagePage.interactive`, les poignées seules reçoivent les gestes. Le jeu livré n'en
contient aucune trace : pas de bouton caché, pas de geste secret. La géométrie
vit dans `AreaEditor` (`lib/application/`, Dart pur) ; la page ne fait que
traduire des gestes en fractions.

**Réserve et listes pleines** — une famille a plus de mots que l'étape n'en
montre (`Stage.visibleWordCount`). Un mot bien classé est remplacé sur place par
un mot de la réserve. Les listes sont **pleines** : une famille s'ouvre quand
tous ses mots sont classés. `WordFamily.goal` permet d'en demander moins, mais
n'est utilisé nulle part — remplir entièrement une catégorie est en soi une aide,
puisque le choix se réduit pour les mots suivants. Les listes n'ont pas à être
de la même taille d'une famille à l'autre.

**Trois nombres à ne pas confondre.** `Stage.visibleWordCount` est le nombre
d'étiquettes **à l'écran** en même temps, toutes familles confondues (6 à la
maison). `drawCount` est le nombre de mots que **chaque famille** met en jeu —
`Stage.drawCount` donne le défaut du lieu, `WordFamily.drawCount` le remplace.
Nul des deux côtés, **sept** (`Stage.defaultDrawCount`, décision de l'auteur
en 0.42.0) — la zone « le reste » comprise, qui tire ses sept mots dans
l'ensemble de ses listes cochées, et non sept par liste. Une liste de moins de
sept mots est **à finir** (option A de l'auteur) : elle n'est pas jouée entière
en silence. Sans réglage, la liste jouait entière, et une zone de douze mots en
exigeait douze. `goal` reste le nombre de mots qui suffisent à ouvrir la
destination.

**Les tests lisent la partie tirée** — une liste plus longue que la partie
garde des mots en réserve que l'enfant ne verra pas. Un test qui classe « les
mots de la famille » les prend donc dans `engine.stage`, jamais dans le lieu
d'origine : sinon il classe des mots que le moteur n'a pas tirés.

**Une zone annonce ce que la partie demande** — « 0 / 7 », et non la
longueur de la liste. `StagePage` prend le nom et la place de chaque zone au
lieu de l'écran, mais le **compte au lieu tiré par le moteur**
(`FamilyDropZone.requiredCount`). Elle prenait tout au lieu de l'écran, et une
liste de douze s'annonçait « 0 / 12 » pour s'ouvrir au septième mot : invisible
tant que les listes jouaient entières sans réglage. La place, elle, doit
rester celle de l'écran : le calage déplace les zones sans relancer la partie.

**Le tirage a lieu dans le moteur, pas dans l'interface** — `StageEngine`
construit l'étape jouée par `stage.drawnWith(random)`, avec le `Random` injecté.
L'interface n'a pas à connaître une règle de jeu, et une liste plus grande que la
partie fait que **rejouer une journée ne redonne pas les mêmes mots**.

**Aucune aide à la lecture** — un mot mal placé est refusé, l'étiquette
tremble et revient, l'enfant réessaie ; rien d'autre ne s'affiche.
`StageEngine` ne compte plus les erreurs, et `Hint` / `HintPolicy` ont
disparu (0.33.0). L'aide par le découpage syllabique a été **retirée par
l'auteur**, l'illustration avait déjà été écartée : avec trois familles, les
possibilités se réduisent d'elles-mêmes et montrer l'image donnerait la
réponse. Ne réintroduire aucune aide sans arbitrage — c'est une décision, pas
un oubli.

**Le tri unique** — une **autre mécanique de lecture**, pas un élément narratif.
Au lieu de trier entre plusieurs familles homogènes, l'enfant trie entre **une
liste et son complément** : ce qui est du thème, et tout le reste. Il n'y a rien
à comparer d'un mot à l'autre, chacun se juge seul contre un seul critère —
c'est plus abstrait, et plus difficile.

La structure le dit, rien n'est déclaré : une famille **sans destination** est
la liste du reste, et sa présence fait du lieu un tri unique (`isSingleSort`).
Corollaire vérifié par `validate()` : un tri unique **n'a qu'une seule sortie**,
celle que le thème ouvre. Deux en feraient un tri ordinaire affublé d'une liste
de rebut, ce qui n'est plus la même mécanique.

**Le reste puise dans des listes cochées (option C)** — `WordFamily.lists`,
`"lists"` dans le JSON. L'auteur choisit le thème, puis les listes **sûres pour
ce thème** ; le jeu y tire des mots absents du thème. Tout prendre dans le
vocabulaire a été écarté : « banane », absente de « Ce qui se mange » mais
écrite ailleurs, serait refusée à l'enfant qui la range à juste titre. Une
liste écrite exprès pour le reste (option A) reste possible — c'est une liste
cochée comme une autre.

**L'exclusion est asymétrique dans un tri unique** : le reste perd les mots du
thème, le thème ne perd rien. Dans un lieu à plusieurs listes, elle reste
symétrique. `Stage.supplyOf` compte ce qu'il reste à chaque famille — la carte
l'affiche et `validate()` en tire ses anomalies, d'un seul calcul.

**Pas de mot seul, pas de liste d'office** — un trajet naît **sans liste**.
L'auteur en crée une ou en réutilise une (`WordListBuilder`, Dart pur), et un
mot n'entre que par une liste. Une liste posée d'office aurait pris un identifiant
tiré du trajet (`en_bus`), que deux aventures se seraient disputé dans le
catalogue global. **Une liste est la même partout où elle sert** : la modifier
d'un trajet la modifie pour tous, et `usagesOf` permet de le dire.

**Chaque liste, chaque mot s'enregistre là où il vit** — `ContentSaver`
réécrit une liste ou un mot modifié **dans son fichier d'origine**, et range ce
qui est neuf dans les fichiers propres à l'aventure (`lists/<id>.json`,
`lexicon/<id>.json`), qu'il déclare au sommaire. Un fichier n'est réécrit que
s'il change, et le fichier propre **garde ce qu'il avait** : il était
auparavant réécrit avec les seules nouveautés, si bien qu'un second
enregistrement effaçait les listes du premier.

**Il n'y a plus de personnage** (0.34.2) — `Character`, `characters.json` et
la réplique qu'un lieu lui prêtait ont été retirés. Le modèle mêlait deux
choses : quelqu'un qui intervient dans l'histoire, et la mécanique du tri
unique, qu'il avait longtemps servi à poser. La mécanique vit désormais dans la
structure ; ce qui restait n'est que de la narration, et c'est au récit de le
porter.

**Pas de champ « type d'étape »** — la nature d'un lieu se lit dans sa structure :
une famille sans destination fait un tri unique, aucune famille fait une fin
(voir l'exception ci-dessous). Ajouter un type serait une information en double,
qui finirait par diverger.

**Une exception, assumée : la fin se déclare** (`Stage.isEnding`, `"ending"`
dans le JSON). L'absence de famille ne suffisait pas à la dire : un lieu qu'on
vient de créer et qu'on n'a pas encore écrit n'en a pas non plus, et passait
donc pour une fin sans que rien ne le signale. C'est bien la redondance que la
règle ci-dessus proscrit — elle n'est acceptée que parce qu'elle est
**vérifiable** : `validate()` refuse qu'une fin porte des familles (*faux*), et
signale un lieu sans famille qui ne se déclare pas fin (*incomplet*). Les deux
ne peuvent donc pas mentir l'un sur l'autre.

**Champ lexical des familles** — les familles d'une étape doivent avoir des
vocabulaires disjoints, et c'est plus contraignant qu'il n'y paraît : « En bus »
et « En voiture » partagent toute la mécanique (moteur, roue, frein, siège,
phare, ceinture), un bus étant une voiture en plus grand. Ne retenir que les
mots propres à l'usage. Pour une nouvelle scène, préférer des familles
naturellement séparées plutôt que d'élaguer après coup.

## 7. Interface

`lib/ui/` n'applique aucune règle : elle transmet les gestes au moteur et affiche
l'état qu'il renvoie. Décider dans un widget si un mot est bien placé dupliquerait
le moteur et ferait diverger les deux.

**Une illustration est du contenu, et se lit par la source** —
`contentImageProvider` (dans `lib/ui/widgets/content_image.dart`) rend un
`ContentPictureImage`, qui lit les octets par `ContentSource.readBytes`. Le
bundle pour le jeu, un dossier de l'appareil ou le dépôt distant pour l'outil.
Les endroits qui affichent une image — scène de jeu, calage, écran de
lecture — passent par là. Deux règles séparées finiraient par
diverger, et l'auteur calerait ses zones sur une image que le jeu ne montre pas.

C'est un `ImageProvider` à part entière et non un `FutureBuilder` : c'est ce
qui le fait entrer dans le cache d'images de Flutter, qui indexe par égalité du
fournisseur. La **source fait partie de son identité** — se connecter au dépôt
doit bien redonner une autre image.

**Aucun autre chemin n'est lu** : ni `assets/…`, ni adresse `http:` ou
`blob:`. Les deux formes étaient tolérées pour un contenu écrit avant la
bascule, et ont été retirées en 0.35.0 (§1).

**Ce que cela a remplacé** — l'image vivait à part : un chemin de fichier sur
l'appareil, une adresse `blob:` dans un navigateur, et deux fichiers choisis
par import conditionnel. Elle ne voyageait donc pas avec le contenu : prise sur
le téléphone, elle n'arrivait jamais sur le poste ; choisie dans un onglet,
elle disparaissait avant d'être affichée, le système révoquant l'adresse. Un
`ContentSink.writeBytes` et un `ContentSource.readBytes` ont supprimé les deux
problèmes et une branche de plateforme.

**Une image se choisit dans le dépôt** (0.37.0) — l'auteur verse ses fichiers
dans `assets/content/pictures/`, sous le nom qu'il veut, et l'outil les
propose : `PictureCatalog` (domaine) les liste, `BundledPictureCatalog` les lit
dans le manifeste du bundle, `PictureChooserPage` les montre en vignettes avec
leur nom. L'outil est compilé à partir du dépôt, comme le jeu : **une image
choisie là existe forcément dans le jeu**. Rien n'est copié ni renommé.

Ce que cela a remplacé : une photothèque qui copiait la photo de l'appareil
sous un nom fabriqué (`gare_1790155902917.jpg`) dans le dossier de travail.
L'image vivait alors sur le dépôt distant, jamais dans le dépôt git, et le jeu
ne l'aurait pas vue ; sur Android, le nom d'origine n'était même pas connu.

**`PictureField` est le seul champ d'image** — le lieu et la page de garde s'en
servent tous deux : chemin saisissable, bouton « Choisir une image », aperçu,
et **alerte quand l'image citée n'est pas dans le dépôt** — une image rangée
autrefois sur le dépôt distant, par exemple, que l'enfant ne verrait jamais.

**Une image qui ne se lit pas dit pourquoi** (0.42.1) — l'aperçu et les
vignettes du sélecteur affichent la raison réelle (`describeImageError`).
« Image introuvable » seul laissait chercher à l'aveugle : l'auteur a vu ses
images échouer dans l'outil, alors que le jeu les montrait, sans rien pour dire
d'où venait l'écart.

**`copyWith` ne sait pas effacer** — `??` garde l'ancienne valeur, si bien que
retirer une illustration serait sans effet et que l'auteur croirait l'avoir
fait. D'où `Stage.copyWith(clearBackgroundAsset: true)`, et `Adventure`
`withStage` / `withOpening` plutôt qu'un `copyWith` : `withStage` refuse un
identifiant inconnu, qui ajouterait un lieu fantôme au lieu d'en corriger un.

**Assets : déclarer chaque répertoire** — Flutter n'embarque pas les
sous-dossiers ; une entrée `assets/` terminée par `/` ne prend que les fichiers
de ce répertoire. Ajouter un sous-dossier de contenu sans l'inscrire dans
`pubspec.yaml` produit une application qui compile, des tests qui passent (ils
lisent le disque) et un jeu qui refuse de s'ouvrir sur l'appareil.
`test/infrastructure/declared_assets_test.dart` compare les fichiers réels aux
déclarations et échoue si l'un manque.

**Un lieu raconte son arrivée, jamais son départ** — `Narrative.onArrival`, et
rien d'autre. L'enfant entre, lit ce qui donne son sens à ce qui va lui être
demandé, classe ses mots, puis clique un trajet : c'est le **lieu suivant** qui
raconte, avec son propre texte. Un `onCompletion` a existé et disait la même
chose deux fois — le contenu livré faisait annoncer l'arrivée à la plage par le
lieu qu'on quittait, avant que la plage ne la raconte à son tour. La narration
appartient à celui qui accueille.

**Ce texte est l'énoncé du jeu, et se lit sur la scène** — en haut, dans le
même cartouche que les mots (`StagePage`), et il y reste quand tous les mots
sont classés. Il situe l'enfant et pose la question que le tri tranche : « Y
ira-t-elle à pied, en bus ou en voiture ? ». Il s'affichait sur un écran de
récit intercalé avant la scène (`StoryMomentPage`, retiré en 0.35.0) ; lu
avant de jouer, sur un écran quitté, il perdait ce rôle. **Aucune consigne
générique** ne l'accompagne — « Pose les mots au bon endroit » a été retirée
par l'auteur, l'énoncé disant déjà ce qu'il faut faire.

**Un seul écran de lecture** (0.41.0) — `NarrationPage` : un titre
facultatif en haut, l'illustration sur toute la largeur, à ses proportions —
elle peut être horizontale —, le texte dessous, et un bouton toujours visible.
La page de garde et la fin s'en servent toutes deux. La fin avait son propre
écran, **sans image** : l'auteur en posait, elles ne paraissaient jamais.

**Page de garde** — `Adventure.opening` porte un titre, une illustration et un
texte, montrés une fois avant le premier lieu (`AdventureOpeningPage`, sur
l'écran de lecture ; le titre de l'aventure sert quand l'ouverture n'en donne
pas). Le lieu de départ garde son énoncé : la page de garde raconte, l'énoncé
demande. C'est un seuil, pas une transition.

**Une fin** se lit sur le même écran : le nom du lieu en titre, son
illustration, son récit, et « Recommencer ». L'éditeur de lieu appelle son
texte « Le récit de fin », et non « L'énoncé » : il n'y a rien à trier.

**Ce que `main.dart` demande doit exister** — l'identifiant d'aventure du
lancement est exposé (`GrisbieApp.defaultAdventureId`) et vérifié par
`test/infrastructure/startup_test.dart`. Aucun test ne démarre `main.dart` :
renommer une aventure sans reprendre cette constante donnait un jeu qui ne
s'ouvre pas, suite entièrement verte. C'est arrivé.

**Un seul geste écrit, et un seul mot le dit** — « Enregistrer » n'existe que
sur `OutlinePage`, et c'est le seul endroit de l'outil qui touche un disque.
Les éditeurs de lieu, de page de garde et de zones disent « Garder » : ils
rendent leur résultat à l'écran du parcours, qui travaille en mémoire. Deux
gestes portant le même mot laisseraient croire que fermer un lieu suffit à le
conserver.

**Mais quitter le parcours ne doit rien jeter en silence** — c'est le revers
de la règle ci-dessus, et il manquait. L'écran rendait bien l'aventure
modifiée, l'accueil l'ignorait, et tout le travail disparaissait sans un mot.
`OutlinePage` retient donc `_unsaved` — toute modification passe par `_change`,
un `setState` direct oublierait le marqueur — et demande à la sortie : rester,
quitter sans enregistrer, ou enregistrer et quitter. Par `PopScope`, pour que
le geste de retour du système passe par là aussi : protéger un seul côté ne
protégerait rien. « Enregistrer et quitter » ne sort que si l'écriture a
**réussi**, sans quoi on perdrait le travail en croyant l'avoir mis à l'abri.

**`ContentSaver` écrit une aventure entièrement** — le fichier d'aventure seul
ne contient que des références : sans son sommaire il est introuvable, sans ses
listes il en cite que personne n'a écrites, sans le lexique ses listes citent
des mots inconnus. Le contrôle qui compte est que **le dossier écrit se
recharge**, et c'est le dernier test de `content_saver_test.dart`.

Deux modes, et ce n'est pas un réglage de confort. `includeUnchanged` recopie
ce que l'outil ne touche pas — lexiques, listes, **autres aventures** —
pour que le dossier se suffise : c'est ce qu'il faut sur un appareil, qui n'a
rien d'autre. À faux, seul ce qui vient d'être écrit est rendu, ce qui convient
quand la destination possède déjà le reste — un dépôt, ou le dossier de
téléchargement d'un navigateur.

**L'accueil reçoit le catalogue d'images tel quel**, pas une fabrique : il
vient du bundle, que se connecter ne change pas.

**Le point d'entrée seul sait où l'on écrit** — `main_author.dart` construit le
puits : le dépôt distant quand l'auteur y est connecté (`RemoteContentStore`),
sinon un dossier de l'appareil (`DeviceContentFolder`) ou le téléchargement du
navigateur (`BrowserContentSink`). Les écrans ne connaissent qu'un rappel
`onSave`, nul quand il n'y a nulle part où écrire.

**On relit par où l'on écrit** — `authorContentSource` monte la source en
miroir du puits : `FallbackContentSource` met le travail devant et le contenu
livré derrière. Au premier lancement le dossier de travail est vide et il n'y a
que le livré ; ensuite c'est le travail qui fait foi, y compris quand il n'a
réécrit qu'une partie des fichiers. Le repli vaut pour l'**absence**, jamais
pour un fichier écrit illisible : masquer une erreur par la version d'origine
ferait croire le travail intact.

**Et une panne n'est pas une absence** — `ContentFileNotFound` nomme la
seconde, et `FallbackContentSource` ne se replie que sur elle. Un `catch (_)`
attrapait tout : un refus du dépôt, une coupure de réseau, un blocage CORS du
navigateur servaient silencieusement le contenu livré. C'est arrivé —
l'aventure était déposée sur le dépôt, la lecture échouait, et l'accueil
affichait imperturbablement la liste des assets. Chaque source traduit donc
l'absence et **laisse remonter le reste** : `RemoteContentStore` ne convertit
que `object-not-found`, jamais `unauthorized`, qui est un refus de la règle et
doit se voir.

C'est aussi la source que `saveAdventure` donne à `ContentSaver`, et **ce
n'était pas un détail** : `includeUnchanged` recopie ce que l'outil ne touche
pas, dont les *autres* aventures. Les prendre aux assets ramenait chacune à sa
version d'origine à chaque enregistrement, effaçant en silence le travail
précédent.

**L'accueil reçoit une fabrique de dépôt, pas un dépôt** — `ContentRepository`
garde le sommaire et les lexiques en mémoire, ce qu'il faut pour jouer et non
pour éditer, et **se connecter change la source**. `AuthorHomePage` rouvre donc
à neuf après un enregistrement comme après un changement de compte, et ouvre
chaque aventure par `loadDraft` : une aventure en cours d'écriture est toujours
invalide.

**Le dépôt distant est un dossier comme un autre** — `RemoteContentStore`
implémente `ContentSource` *et* `ContentSink`, avec la même arborescence
qu'`assets/content/`. C'est ce qui permet à `ContentSaver` et
`ContentRepository` de ne rien savoir du réseau : le pont entre le poste et le
téléphone n'a demandé aucune ligne de leur part.

**Ce que l'écran d'accueil dit, et pourquoi là** — où va l'enregistrement se
lit sur `AuthorHomePage`, une fois, plutôt que dans le message qui suit chaque
enregistrement : c'est **avant** de travailler qu'on veut le savoir. L'UID y
figure aussi, parce que c'est lui que la règle du bucket doit nommer.

**L'interface ne sait rien du fournisseur** — `AuthorAccount` (domaine) est une
interface ; `AuthorSession` l'implémente avec `firebase_auth`. C'est ce qui rend
l'écran de connexion éprouvable sans Firebase, sans réseau et sans compte.

**Le téléchargement est un dépannage, et il se voit** : un navigateur ne crée
pas de dossier, chaque fichier descend séparément et son nom porte le chemin
aplati (`adventures_plage.json`). Il faut les reposer à la main dans
`assets/content/`. C'est ce qu'un dépôt distant remplacera.

**L'écran de construction du parcours** — `OutlinePage` reprend la forme du
croquis papier de l'auteur : un point porte une lettre, ses trajets se lisent
dessous, et **chaque arrivée devient à son tour une carte plus bas**, prête à
être prolongée. Un lieu sans trajet — celui qu'on vient de créer — a donc sa
carte comme les autres : ne pas l'afficher le rendait invisible et impossible à
prolonger, ce qui vidait l'écran de son usage. Le lettrage vient
d'`AdventureOutline` et **ne se stocke jamais** : il bouge dès qu'on insère un
trajet. La page ne décide rien — elle passe les demandes à `AdventureBuilder`
et réaffiche ce qu'il rend. Elle travaille **en mémoire** et rend l'aventure
modifiée à l'appelant ; rien ne l'enregistre encore.

**Cliquer le titre ouvre ce que le lieu porte** — `StageEditorPage` : le nom,
l'illustration, les zones de dépôt et l'énoncé. **Les listes
de mots n'y sont pas** : elles appartiennent à un *trajet*, pas à un lieu, et
une même liste sert à plusieurs endroits — les mettre là laisserait croire
qu'on les modifie pour ce lieu seul. Le calage (`AreaEditorPage`) s'ouvre
depuis là, sur l'étape **en cours d'édition**, illustration comprise, et rend
l'étape calée ; sans quoi l'auteur poserait ses zones sur l'image d'avant.

**Toucher un trajet ouvre sa liste** — `WordListPage`. Un trajet sans liste
propose d'en créer une ou d'en réutiliser une ; ensuite, on tape des mots, un
seul champ, et **le curseur y revient** après chaque ajout, par Entrée comme
par le bouton : on enchaîne sans reprendre la souris. Le reste d'un tri unique se
compose en **cochant** des listes, celle du thème exclue. Une liste citée
ailleurs le dit en tête (« sert aussi à… ») : la modifier la modifie partout.
La page dit « Garder » comme les autres éditeurs.

**Chaque trajet dit s'il a de quoi jouer** — sur la carte, `7/7` ou `3/7`, ou
« pas de liste ». C'est `Stage.supplyOf`, exposé par `OutlineTrip.supply` et
affiché par `SupplySummary`, en court sur la carte et en long sur l'écran de
liste. L'accueil charge la bibliothèque (`ContentRepository.loadLibrary`) avant
d'ouvrir le parcours.

**Une boîte de dialogue garde son propre champ** — un contrôleur de texte
libéré au retour de `showDialog` est encore lu par l'animation de fermeture,
et Flutter échoue. `_TextDialog` est donc un widget à état.

**La page de garde a sa carte, au-dessus du premier lieu** — plus discrète et
sans lettre : ce n'est pas un point du parcours, rien n'en part. Elle existe
même quand il n'y a pas de page de garde, sans quoi il n'y aurait aucun endroit
où en créer une. `OpeningEdit` enveloppe le résultat de son éditeur parce que
**renoncer et retirer la page donneraient tous deux `null`**.

**Une fin garde sa carte, mais n'a aucun bouton** — la journée s'y arrête, et
proposer d'en repartir contredirait ce que la carte vient d'annoncer. Sa carte
reste, elle : il y aura une illustration et un texte d'arrivée à y poser. Une
fin créée par erreur **se rouvre depuis sa structure** (ci-dessous).

**Trois gestes sur une carte, trois choses différentes** — le titre ouvre ce
que le lieu montre (`StageEditorPage`), un trajet ouvre sa liste
(`WordListPage`), et la **ligne de nature** — « Plusieurs listes », « Tri
unique », « Fin », avec une icône de réglage — ouvre sa **structure**
(`StageStructurePage`) : changer de nature, renommer, rediriger ou retirer un
trajet. Aucun écran ne permettait de revenir sur un choix de circuit. Un lieu
à définir — une fin qu'on vient d'y rouvrir — y reçoit **les trois réponses
de la carte** : renvoyer à la carte pour le redéfinir était une impasse.

Les conversions gardent ce qui peut l'être (`AdventureBuilder` :
`convertToSingleSort` avec le trajet choisi pour thème, `convertToSorting`,
`convertToEnding`, `reopen`, `renameTrip`, `redirectTrip`, `removeTrip`), et
chaque retrait se confirme en nommant ce qui part. **Aucun lieu ne disparaît
en passant** : celui que plus rien n'atteint reste, « Aucun chemin ne mène
ici », et sa carte offre alors — alors seulement — « Supprimer ce lieu »
(`removeStage`, qui refuse un lieu encore atteint et le point de départ).

**Le répertoire des fins** — une fin porte un écran, une illustration et un
texte. Plusieurs chemins qui aboutissent au même endroit doivent donc partager
la **même**, sans quoi l'auteur écrit deux fois la même arrivée et les deux
finissent par différer. `NewTrip.existingStageId` relie un trajet à un lieu déjà
écrit au lieu d'en créer un ; `AddTripsPage` propose **tous les lieux déjà
écrits** (`existingPlaces`), celui d'où l'on part excepté, et la structure
d'un lieu permet de rediriger un trajet.

**Une boucle est permise, et signalée** — revenir en arrière crée un chemin
où l'enfant peut tourner en rond. La spécification ne l'interdit pas, et
l'auteur a voulu garder le geste. `Adventure.validate()` nomme chaque trajet
d'une boucle avec une troisième sévérité, `IssueSeverity.warning`, *à
vérifier* : elle **ne bloque ni le jeu ni la mention « jouable »**
(`ContentIssue.blocksPlay`), et l'écran la montre en orange.

Le nom saisi reste celui du **trajet**, jamais celui du lieu rejoint : c'est ce
que l'enfant lit sur la zone de dépôt. L'écran le propose par commodité quand le
champ est vide, et il reste modifiable.

**Un trajet et le lieu qu'il atteint portent deux noms** — « En bus » mène à
« La gare ». Le trajet dit le moyen, le lieu dit l'arrivée, et c'est tout
l'intérêt : l'enfant classe des mots sous « En bus », puis découvre « La gare ».
`NewTrip` porte donc `name` **et** `locationName`, et `AddTripsPage` demande les
deux, le second proposé d'après le premier et détaché dès qu'on l'écrit. Le
second vide, le trajet prête le sien — le cas courant.

L'outil n'en demandait qu'un et baptisait le lieu du nom du trajet. Deux
conséquences, et la seconde est la pire : il ne savait **pas écrire le contenu
livré**, et il enseignait à l'auteur une règle que ce contenu dément — au point
de faire passer l'aventure livrée pour un affichage cassé.

**L'identifiant du lieu vient du lieu**, pas du trajet : « La gare » donne
`gare`, comme le contenu livré l'écrit à la main. L'identifiant de la *famille*,
lui, vient du trajet (`en_bus`) — elle lui appartient.

**Un trajet dit où il mène** — `OutlineTrip.destinationName`, affiché
« En bus → La gare » sur sa ligne. La lettre du lieu suffisait à faire le lien,
mais obligeait à descendre chercher sa carte pour savoir duquel il s'agit ; sur
le croquis papier, la flèche portait les deux bouts. Le nom est tu quand il
répète le trajet : « En bus → En bus » se lirait comme un défaut.

**La nature se dit sur la carte du lieu, pas sur le trajet** — la question
est « que fait l'enfant ici ? », et elle se pose au lieu : ranger dans
plusieurs listes, faire un tri unique, ou lire la fin (du texte, pas de jeu).
`StageNature` la lit dans la structure ; un lieu sans famille ni marqueur de
fin est **à définir**, et sa carte pose la question avec trois boutons. Tout
lieu créé naît ainsi. L'outil demandait autrefois la nature du lieu
**d'arrivée** au moment d'ajouter les trajets, avec un sélecteur de nombre
qui comptait les trajets et se lisait comme un nombre de listes — l'auteur
l'a pris pour un défaut, à juste titre.

`AdventureBuilder` porte les trois réponses : `addTrips` (plusieurs listes,
et ajouter ensuite), `defineAsSingleSort` (le thème, sa sortie et la liste du
reste, posés ensemble) et `defineAsEnding`. Les deux derniers refusent un lieu
déjà défini : redéfinir jetterait ses listes. `AddTripsPage` ne fait plus que
nommer les sorties — plusieurs, ou le seul thème d'un tri unique
(`allowsOneTripOnly`), sans nombre à choisir.

**Sept mots par zone** — `AdventureBuilder.defaultDrawCount`, qui n'est que
`Stage.defaultDrawCount`, est encore posé sur le lieu quand il reçoit ses
premières listes : le réglage se lit ainsi dans le fichier. Un lieu déjà écrit
garde ce qu'il demandait.

**Essayer sur l'appareil** (0.38.0) — ce qui se règle sur l'ordinateur doit se
vérifier au doigt, sur l'écran réel du téléphone. L'outil y joue donc le **vrai
jeu**, et non une imitation : « Essayer ce lieu », sur la carte, monte
`StagePage` sur le lieu seul et revient au parcours au premier départ ;
« Jouer l'aventure », en tête d'écran, monte `AdventurePage` sur l'aventure
entière. Les deux jouent **ce qui est à l'écran**, enregistré ou non.
`Stage.canBeTriedAlone` dit si un lieu se joue seul : des familles, dont
aucune n'est vidée par les mots communs — une famille vide s'ouvrirait
d'elle-même, sans rien trier. L'aventure entière ne se joue que **jouable**,
et `PreloadedAdventureRepository` refuse, comme le jeu, ce que le jeu
refuserait.

**Intégrer au dépôt** (0.39.0) — publier, c'est verser l'aventure dans
`assets/content/` de la copie du dépôt. Depuis Chrome ou Edge, l'auteur
désigne ce dossier (`BrowserContentFolder`, par l'accès aux fichiers du
navigateur), et `ContentIntegrator` y écrit avec le même `ContentSaver` que
l'enregistrement, **le dossier du dépôt servant de base** : ses listes et ses
lexiques sont ceux que l'aventure complète, ou corrige là où ils vivent. Seul
ce qui change est écrit. **Rien ne s'écrit si un contrôle échoue** : le
dossier doit porter `index.json` — désigner `assets/` par mégarde écrirait là
où le jeu ne cherche pas —, l'aventure doit être jouable, et chaque image
citée (`Adventure.picturePaths`) doit être dans `pictures/`. Un dépôt à moitié
modifié serait pire qu'un refus. Il reste à faire le commit, puis à recompiler.

`ContentStore` (domaine) nomme ce qui se lit **et** s'écrit : le dossier du
dépôt, le dépôt distant. Le bouton ne paraît que si `canPickContentFolder()` —
ni Firefox ni Safari n'ouvrent un dossier du poste.

Un marqueur « en test » dans le jeu a été écarté : il aurait fallu verser les
brouillons dans le dépôt pour les voir sur le téléphone, et chaque retouche
aurait demandé commit, compilation et réinstallation. **Une aventure est
publiée quand elle est dans le dépôt**, et le jeu ne voit que ce qui l'est.

**Où en est l'aventure** — `ContentReadiness`, déduite des anomalies et de
rien d'autre : *jouable* (aucune), *pas complète* (des manques), *contient
des erreurs* (une faute). « Jouable » est réservé à ce que le jeu ouvrira
vraiment ; l'écran du parcours l'annonce en tête.

**Tests d'écran et fenêtre** — un `ListView` ne construit que ce qui est
visible : sur la fenêtre de test par défaut, les cartes du bas n'existent pas
dans l'arbre et les recherches échouent sans que rien ne soit cassé. Les tests
de `OutlinePage` agrandissent donc la fenêtre (`tester.view.physicalSize`).

**Une seule résolution d'image** — `BackgroundImageSize` fournit les dimensions
réelles d'une illustration, et sert à la fois à la scène de jeu et à l'outil de
calage. Deux résolutions séparées finiraient par diverger, et l'auteur calerait
ses zones sur une géométrie qui n'est pas celle du jeu.

**Tests de widget et lecture disque** — `testWidgets` fait tourner une horloge
simulée, où une lecture de fichier réelle ne se résout **jamais** : le test
tourne sans fin. Charger le contenu dans `setUpAll`, jamais dans le corps d'un
`testWidgets`, et passer `PreloadedAdventureRepository` à la page.

**L'illustration n'est jamais recadrée** — elle est montrée en entier et calée
en bas, dans la place que le bandeau laisse, la bande libre étant comblée par
`Stage.backgroundColor`. Un
recadrage « cover » ferait sortir de l'écran un quart de l'image sur un
téléphone allongé, et les zones ancrées au décor sortiraient avec lui.
`computeSceneRect` est une fonction pure, éprouvée par
`test/ui/scene_geometry_test.dart` sur quatre appareils réels : elle vérifie que
l'image tient, garde ses proportions, et que chaque zone reste à l'écran et
assez grande pour un doigt.

**Le bandeau est posé au-dessus de la scène, jamais dessus** (0.36.0, option
A choisie par l'auteur). Il était superposé à l'illustration, or les zones
sont ancrées au décor et la première commence vers 29 % de la hauteur : un
bandeau trop haut la recouvrait et interceptait le doigt, sans le moindre
message. L'énoncé l'a rendu inévitable — deux phrases sur un 360×640
recouvraient la zone du bus de 22 px. L'illustration occupe désormais ce que
le bandeau laisse : le recouvrement est impossible quelle que soit la
longueur du texte, et l'image rapetisse d'autant sur un petit écran.
`test/ui/real_content_layout_test.dart` monte l'étape réelle, munie de
l'énoncé que l'auteur a écrit pour elle, sur trois formats d'écran, et
`stage_page_test.dart` pose une zone tout en haut de l'image sous un énoncé
très long.

## 8. Documentation

| Fichier | Contenu |
|---|---|
| `docs/current.md` | État courant, version, travail en cours |
| `docs/versions.md` | Historique des versions et procédure de versioning |
| `docs/TODO.md` | Backlog |
| `docs/Commandes.md` | Ce que l'on tape : lancer, vérifier. Une commande n'y entre qu'une fois réellement exécutée |
| `docs/Specification_jeu_decouverte_lecture.md` | Cadrage fonctionnel du jeu |
| `docs/Format_fichier_aventure.md` | **Contrat** — structure des fichiers de contenu, pour qui écrit une aventure |
| `docs/Noms_et_identifiants.md` | **Contrat** — table de vérité des noms, identifiants Android, Firebase, signature |
