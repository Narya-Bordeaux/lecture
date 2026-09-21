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
