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

**Version actuelle : 0.23.1+39** — le niveau test est jouable : moteur, contenu et
interface de l'étape de départ. Une seule aventure existe, et la progression
n'est pas encore enregistrée. Un outil d'auteur existe sur un second point
d'entrée (`lib/main_author.dart`) : il cale les zones de dépôt sur l'illustration
réelle. Le chantier en cours l'étend à la création d'une journée entière, voir
`docs/current.md`.

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

**Six dépendances tierces** — `image_picker` et `path_provider` (équipe
Flutter), `web` (équipe Dart), `firebase_core`, `firebase_storage` et
`firebase_auth`. Elles ne servent qu'à l'outil d'auteur : choisir
l'illustration d'un lieu dans l'appareil, savoir où écrire, rendre les fichiers
par le téléchargement d'un navigateur, et déposer le contenu sur le dépôt
distant.
Le `pubspec.yaml` étant partagé, **elles sont embarquées dans le jeu**, qui ne
les appelle jamais. Ce n'est pas une promesse, c'est vérifié :
`test/infrastructure/author_only_test.dart` exige que les greffons ne soient
importés que par l'infrastructure dédiée, que `DevicePictureLibrary` et
`AuthorRemote` ne se construisent que dans `main_author.dart`, que **rien
n'initialise Firebase** hors de `author_remote.dart`, et que `main.dart` ne
mène à aucun écran d'auteur. `image_picker` a été préféré à un sélecteur de fichiers
général : sur Android 13 et au-delà il passe par le Photo Picker du système,
qui **ne demande aucune permission**.

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

Cinq fichiers, un rôle chacun : `index.json` dit ce qui existe, `lexicon/*.json`
définit chaque mot **une seule fois**, `lists/*.json` regroupe les mots par thème,
`characters.json` porte les personnages, et `adventures/*.json` assemble le tout
par références. Un mot défini à deux endroits finirait découpé de deux façons
différentes ; le chargement refuse le doublon.

**Trois objets, trois questions** — et c'est ce qui justifie le troisième :
`Word` dans le lexique dit **comment le mot s'écrit et se découpe**, `WordList`
dit **de quoi il parle**, `WordFamily` dit **où cette liste se pose dans ce lieu**,
sous quel nom et vers quelle sortie. Le lexique refuse le doublon, et pourtant un
mot doit pouvoir appartenir à plusieurs thèmes ; une famille porte un nom affiché,
une destination et une zone, toutes choses propres à un lieu. Il manquait l'objet
du milieu. Une famille **cite** une liste (`"list": "bus"`), elle ne porte pas ses
mots.

**Tout le contenu est en français, identifiants compris** — ids d'étapes, de
familles, de personnages. Le jeu n'a pas vocation à être traduit, et une clé
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

Le découpage syllabique est une donnée du contenu, jamais calculé : le français n'a
pas de règle de syllabation assez sûre pour être automatisée, et une syllabe fausse
tromperait l'enfant sur ce que le jeu cherche précisément à travailler.

**Le découpage suit les sons, pas les lettres** — règle pédagogique choisie contre
la syllabation graphique académique : `["a", "rê"]` pour « arrêt ». Il n'a donc pas
à reconstituer l'orthographe, et **aucun test ne doit l'exiger** : un tel contrôle
interdirait précisément les découpages recherchés. Seule l'absence de découpage est
signalée. L'enfant voit les deux de toute façon, le mot écrit sur l'étiquette et son
découpage juste en dessous.

**Un mot ne doit jamais apparaître dans le nom de sa famille** (« bus » dans « En
bus ») : il se classerait en comparant les lettres, sans être compris. `validate()`
le détecte et un test le vérifie.

**Décor et zones** — l'illustration d'une étape (`backgroundAsset`) et l'endroit de
chaque zone de dépôt (`WordFamily.area`) sont aussi du contenu. Les zones sont
repérées en fractions de l'image, jamais en pixels, pour rester collées au décor
quelle que soit la taille de l'écran.

Ces fractions ne s'écrivent pas à la main : `lib/main_author.dart` est un
**second point d'entrée**, l'outil de calage. Il monte l'étape réelle en aperçu
inerte — décor, bandeau, cadres — et pose par-dessus des poignées de
déplacement. Le JSON produit part dans le presse-papiers. Le jeu livré n'en
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
Nul des deux côtés, la liste joue entière : c'est le cas du contenu livré, dont
le comportement n'a donc pas changé. `goal` reste le nombre de mots qui suffisent
à ouvrir la destination.

**Le tirage a lieu dans le moteur, pas dans l'interface** — `StageEngine`
construit l'étape jouée par `stage.drawnWith(random)`, avec le `Random` injecté.
L'interface n'a pas à connaître une règle de jeu, et une liste plus grande que la
partie fait que **rejouer une journée ne redonne pas les mêmes mots**.

**Une seule aide** — le découpage syllabique, dès la première erreur sur le mot.
L'illustration a été écartée : avec trois familles, les possibilités se
réduisent d'elles-mêmes et montrer l'image donnerait la réponse. Ne pas la
réintroduire sans arbitrage — c'est une décision, pas un oubli.

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

Les mots de la liste du reste **s'écrivent**, ils ne se devinent pas : il
n'existe pas de « tout le vocabulaire moins le thème », et un ramassage
automatique sortirait un mot appartenant vraiment au thème, que le jeu
refuserait. C'est là que la liste réutilisable rapporte le plus : **une** liste
d'objets hétéroclites sert tous les tris uniques du jeu, chacun en retranchant
son propre thème par l'exclusion décrite plus haut.

**Le personnage est un ornement** — un `character` et sa réplique se posent sur
n'importe quel lieu, et ne définissent aucune mécanique. Un tri unique peut se
passer de personnage ; un lieu ordinaire peut en porter un. L'outil d'auteur n'en
invente jamais.

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

**Bundle, réseau ou disque : une seule règle** — `contentImageProvider` (dans
`lib/ui/widgets/content_image.dart`) décide d'où vient une illustration. Un
chemin commençant par `assets/` vient du bundle, une adresse (`http:`,
`https:`, `blob:`) du réseau, et tout le reste du disque. Les
assets étant **scellés au build**, une image que l'auteur vient d'ajouter sur
son téléphone n'y est pas et n'y sera qu'après un commit ; l'édition doit
pourtant déjà fonctionner dessus. Les quatre endroits qui affichent une image —
scène de jeu, calage, page de garde, moment de récit — passent par là. Deux
règles séparées finiraient par diverger, et l'auteur calerait ses zones sur une
image que le jeu ne montre pas.

**« Le disque » n'a pas le même sens partout** : un navigateur n'en a pas. La
branche est donc choisie **à la compilation**, par import conditionnel —
`local_image_provider_io.dart` (un `FileImage`) là où `dart:io` existe,
`local_image_provider_web.dart` (un `NetworkImage`) sinon. C'est ce qui permet
au même code de tourner sur téléphone et dans Chrome.

**Choisir l'image dans l'appareil** — `PictureLibrary` (domaine) est une
interface, injectée par constructeur et transmise de proche en proche depuis
`main_author.dart` ; `DevicePictureLibrary` (infrastructure) l'implémente avec
`image_picker`. Nulle, le bouton ne paraît pas et le champ reste saisissable au
clavier : c'est le cas des tests, et **du navigateur**, qui n'a pas de disque où
ranger la copie. Ce n'est pas un manque, c'est le partage voulu — la structure
et les textes sur un poste, les images sur le téléphone.

**L'image choisie est recopiée** (`PictureStore`) : le sélecteur rend un
fichier de **cache**, qu'Android peut purger en cours de session — l'image
disparaîtrait sans que rien ne l'explique. Le nom de la copie porte un
horodatage, sans lequel une seconde photo pour le même lieu écrirait au même
chemin : le cache d'images de Flutter, qui indexe par chemin, continuerait
d'afficher l'ancienne et le geste paraîtrait sans effet.

Une image ainsi prise est **une image de travail** : l'éditeur le dit sous le
champ. Le jeu ne la verra qu'une fois copiée dans `assets/pictures/` et le
contenu recompilé.

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
appartient à celui qui accueille. Une étape se joue donc en **deux temps**,
récit puis jeu.

**Page de garde** — `Adventure.opening` porte un titre, une illustration et un
texte, montrés une fois avant le premier lieu (`AdventureOpeningPage`). Quand
elle existe, le lieu de départ n'a pas de `onArrival` : deux écrans de texte
d'affilée dont le second redit le premier font attendre l'enfant pour rien. Sa mise
en page diffère des moments de récit : le titre annonce, l'image occupe la
largeur à ses proportions — elle peut être horizontale —, le texte se lit
dessous. C'est un seuil, pas une transition.

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

**`ContentSaver` écrit une aventure entièrement** — le fichier d'aventure seul
ne contient que des références : sans son sommaire il est introuvable, sans ses
listes il en cite que personne n'a écrites, sans le lexique ses listes citent
des mots inconnus. Le contrôle qui compte est que **le dossier écrit se
recharge**, et c'est le dernier test de `content_saver_test.dart`.

Deux modes, et ce n'est pas un réglage de confort. `includeUnchanged` recopie
ce que l'outil ne touche pas — lexiques, personnages, **autres aventures** —
pour que le dossier se suffise : c'est ce qu'il faut sur un appareil, qui n'a
rien d'autre. À faux, seul ce qui vient d'être écrit est rendu, ce qui convient
quand la destination possède déjà le reste — un dépôt, ou le dossier de
téléchargement d'un navigateur.

**Le point d'entrée seul sait où l'on écrit** — `main_author.dart` construit le
puits : le dépôt distant quand l'auteur y est connecté (`RemoteContentStore`),
sinon un dossier de l'appareil (`DeviceContentSink`) ou le téléchargement du
navigateur (`BrowserContentSink`). Les écrans ne connaissent qu'un rappel
`onSave`, nul quand il n'y a nulle part où écrire.

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
l'illustration, les zones de dépôt et les deux moments de récit. **Les listes
de mots n'y sont pas** : elles appartiennent à un *trajet*, pas à un lieu, et
une même liste sert à plusieurs endroits — les mettre là laisserait croire
qu'on les modifie pour ce lieu seul. Le calage (`AreaEditorPage`) s'ouvre
depuis là, sur l'étape **en cours d'édition**, illustration comprise, et rend
l'étape calée ; sans quoi l'auteur poserait ses zones sur l'image d'avant.

**La page de garde a sa carte, au-dessus du premier lieu** — plus discrète et
sans lettre : ce n'est pas un point du parcours, rien n'en part. Elle existe
même quand il n'y a pas de page de garde, sans quoi il n'y aurait aucun endroit
où en créer une. `OpeningEdit` enveloppe le résultat de son éditeur parce que
**renoncer et retirer la page donneraient tous deux `null`**.

**Une fin garde sa carte, mais perd son bouton** — la journée s'y arrête, et
proposer d'en repartir contredirait ce que la carte vient d'annoncer. Sa carte
reste, elle : il y aura une illustration et un texte d'arrivée à y poser.
`AdventureBuilder` continue d'accepter qu'on prolonge une fin — sans quoi le
marqueur et la structure pourraient se contredire — mais l'écran ne l'offre
plus. **Conséquence assumée : une fin créée par erreur ne se rouvre pas depuis
cet écran** ; c'est noté dans `TODO.md`.

**Le répertoire des fins** — une fin porte un écran, une illustration et un
texte. Plusieurs chemins qui aboutissent au même endroit doivent donc partager
la **même**, sans quoi l'auteur écrit deux fois la même arrivée et les deux
finissent par différer. `NewTrip.existingStageId` relie un trajet à un lieu déjà
écrit au lieu d'en créer un ; `AddTripsPage` propose les fins existantes
(`Adventure.endings`) dès qu'il y en a. Le mécanisme vaut pour n'importe quel
lieu — l'écran ne l'offre que pour les fins, les seules où la convergence est
sûre de ne pas créer de boucle.

Le nom saisi reste celui du **trajet**, jamais celui du lieu rejoint : c'est ce
que l'enfant lit sur la zone de dépôt. L'écran le propose par commodité quand le
champ est vide, et il reste modifiable.

**L'ajout de trajets : la nature d'abord, une seule par lot** — `AddTripsPage`
pose en tête ce que l'enfant trouvera au bout (plusieurs listes, tri unique,
une fin), puis seulement le nombre. La nature décide de la mécanique, le nombre
n'est qu'une commodité de saisie. Elle valait auparavant trajet par trajet, ce
qui répétait trois pavés d'explication sous chaque nom et laissait composer un
lot bigarré.

**Mais un lieu peut mener à des natures différentes** : « Devant la maison »
ouvre sur un tri à plusieurs listes et sur deux fins. L'interdiction porte donc
sur **un ajout**, jamais sur un lieu — sans quoi l'outil ne saurait plus écrire
l'aventure livrée. L'écran le dit, et le rappel « partent déjà d'ici » sert à
revenir.

**« Une seule sortie » porte sur l'arrivée, pas sur le départ** — ouvrir
plusieurs tris uniques depuis un même carrefour est légitime, chacun ayant sa
propre liste du reste. C'est `AddTripsPage.allowsOneTripOnly` qui traite
l'autre sens : ajouter **depuis** un tri unique n'admet qu'un trajet.

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
en bas, la bande libre du haut étant comblée par `Stage.backgroundColor`. Un
recadrage « cover » ferait sortir de l'écran un quart de l'image sur un
téléphone allongé, et les zones ancrées au décor sortiraient avec lui.
`computeSceneRect` est une fonction pure, éprouvée par
`test/ui/scene_geometry_test.dart` sur quatre appareils réels : elle vérifie que
l'image tient, garde ses proportions, et que chaque zone reste à l'écran et
assez grande pour un doigt.

**Piège de mise en page, vérifié par les tests** — le bandeau des mots occupe le
haut de l'écran, or les zones sont ancrées au décor et la première commence vers
29 % de la hauteur. Un bandeau trop haut la recouvre et intercepte le doigt : le
mot n'atteint jamais sa cible, sans le moindre message. `test/ui/real_content_layout_test.dart`
monte l'étape réelle sur trois formats d'écran et échoue si cela se reproduit.
Tout changement de taille dans le bandeau doit être revalidé là.

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
