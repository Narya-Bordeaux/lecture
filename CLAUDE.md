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

**Version actuelle : 0.11.0+24** — le niveau test est jouable : moteur, contenu et
interface de l'étape de départ. Une seule aventure existe, et la progression
n'est pas encore enregistrée. Un outil d'auteur existe sur un second point
d'entrée (`lib/main_author.dart`) : il cale les zones de dépôt sur l'illustration
réelle. Le chantier en cours l'étend à la création d'une journée entière, voir
`docs/current.md`.

**Plateformes visées** : Web, Android, Windows. iOS et macOS ne sont pas visés — le
dossier `ios/` a été supprimé en 0.1.1, voir `docs/TODO.md` pour le régénérer.
Seul `android/` est configuré à ce jour ; Web et Windows restent à ajouter.

**Noms et identifiants** : la table de vérité est
`docs/Noms_et_identifiants.md`, contrôlée par
`test/infrastructure/android_packaging_test.dart`. Le jeu s'appelle **Grisbie**
sous l'icône, « Les Aventures de Grisbie » sur la fiche Play Store, et
`fr.naryabordeaux.grisbie` pour Android — **cet identifiant sera définitif dès la
première publication**. Le package Dart est `grisbie`. Ne renommer aucun de ces
éléments sans reprendre le document.

**Pas de serveur** : aucune donnée ne quitte l'appareil. La progression est stockée
localement. Le public étant mineur, toute proposition d'ajout d'un backend, d'un
compte ou d'une télémétrie doit être posée à l'utilisateur, jamais introduite d'office.

**Deux saveurs Android**, `jeu` et `auteur` — le jeu ne contacte rien, l'outil
d'auteur dépose le contenu sur Firebase Storage. Sur Android, le SDK Firebase
s'initialise seul dès que `google-services.json` est présent : ce fichier ne vit
donc que dans `android/app/src/auteur/`, et un test le refuse ailleurs. La saveur
auteur porte le suffixe `.auteur`, ce qui rend impubliable un jeu construit par
erreur avec elle. **Une saveur ne choisit pas le point d'entrée Dart** : `--flavor`
et `-t` s'apparient à la main, voir `docs/Noms_et_identifiants.md`.

## 2. Environnement

- `flutter` / `dart` : **disponibles** — Flutter 3.47.5 / Dart 3.13.4, installés dans
  `/opt/flutter` par le hook de démarrage de session
  (`.claude/hooks/session-start.sh`). Le PATH est déjà positionné ; au besoin :
  `export PATH="/opt/flutter/bin:$PATH"`. L'avertissement « running as root » est
  inoffensif.
- `node` : disponible (v22).
- **Builds Android, Web et Windows impossibles ici** : ni SDK Android, ni
  toolchain Windows, ni navigateur de test. Flutter n'est installé que pour
  l'analyse statique, les tests et la gestion des dépendances.

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
définit chaque mot **une seule fois**, `characters.json` porte les personnages, et
`adventures/*.json` assemble le tout par références. Un mot défini à deux endroits
finirait découpé de deux façons différentes ; le chargement refuse le doublon.

**Tout le contenu est en français, identifiants compris** — ids d'étapes, de
familles, de personnages. Le jeu n'a pas vocation à être traduit, et une clé
technique anglaise n'ajoutait qu'un détour : il fallait savoir qu'« arrêt »
s'appelait `bus_stop` pour l'employer. Seuls les noms de champs JSON restent en
anglais, puisqu'ils portent directement les champs Dart.

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

Deux règles issues de la spécification, à respecter dans les données comme dans le
moteur :
- Les mots **ambigus** (raisonnablement classables dans plusieurs familles présentes
  à la même étape) sont à proscrire. `Stage.validate()` les détecte, et un test le
  vérifie sur chaque aventure livrée.
- Compléter une famille **ouvre** sa destination sans y envoyer l'enfant. Plusieurs
  destinations peuvent être ouvertes à la fois ; seul un départ explicite termine
  l'étape.

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

**Une seule aide** — le découpage syllabique, dès la première erreur sur le mot.
L'illustration a été écartée : avec trois familles, les possibilités se
réduisent d'elles-mêmes et montrer l'image donnerait la réponse. Ne pas la
réintroduire sans arbitrage — c'est une décision, pas un oubli.

**Rencontre et classeur sans issue** — une étape portant un `character` est une
rencontre : un personnage pose une question, et l'enfant trie entre le thème et
un classeur de rebut. Ce dernier est une famille **sans destination**, qui
n'ouvre donc aucun chemin. Les leurres sont écrits à la main, jamais tirés au
hasard : un tirage pourrait sortir un mot appartenant vraiment au thème, et le
jeu refuserait une bonne réponse.

**Pas de champ « type d'étape »** — la structure le dit : un `character` signale
une rencontre. Ajouter un type serait une information en double, qui finirait
par diverger.

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

**Assets : déclarer chaque répertoire** — Flutter n'embarque pas les
sous-dossiers ; une entrée `assets/` terminée par `/` ne prend que les fichiers
de ce répertoire. Ajouter un sous-dossier de contenu sans l'inscrire dans
`pubspec.yaml` produit une application qui compile, des tests qui passent (ils
lisent le disque) et un jeu qui refuse de s'ouvrir sur l'appareil.
`test/infrastructure/declared_assets_test.dart` compare les fichiers réels aux
déclarations et échoue si l'un manque.

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
