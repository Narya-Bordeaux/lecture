# Noms et identifiants

Table de vérité des noms du projet : ce qui s'appelle comment, où cela vit, et
ce qui n'est plus modifiable une fois publié.

`test/infrastructure/android_packaging_test.dart` contrôle la partie Android de
cette table. Changer un nom ici sans le reporter dans le code — ou l'inverse —
fait échouer la suite.

## La table

| Élément | Valeur | Où elle vit |
|---|---|---|
| Nom de la fiche Play Store | **Les Aventures de Grisbie** | Play Console, **pas dans le dépôt** |
| Nom sous l'icône, jeu | **Grisbie** | `android/app/src/jeu/res/values/strings.xml` |
| Nom sous l'icône, outil d'auteur | **Grisbie auteur** | `android/app/src/auteur/res/values/strings.xml` |
| Identifiant Android **définitif** | `fr.naryabordeaux.grisbie` | `applicationId` et `namespace`, `android/app/build.gradle.kts` |
| Identifiant de l'outil d'auteur | `fr.naryabordeaux.grisbie.auteur` | `applicationIdSuffix` de la saveur `auteur` |
| Saveurs Gradle | `jeu`, `auteur` | dimension `usage`, `android/app/build.gradle.kts` |
| Paquet Kotlin | `fr.naryabordeaux.grisbie` | `android/app/src/main/kotlin/fr/naryabordeaux/grisbie/` |
| Package Dart interne | `grisbie` | `pubspec.yaml`, et tous les `import 'package:grisbie/…'` |
| Titre de l'application | Les Aventures de Grisbie | `UiStringsFr.appTitle` |
| Projet Firebase, **unique** | `grisbie-43ee9` | console Firebase |
| App Android enregistrée dans Firebase | `fr.naryabordeaux.grisbie.auteur` | console Firebase |
| Pseudo de cette app dans Firebase | Grisbie auteur – Android | console Firebase |

Le manifeste ne porte plus de libellé en dur : `android:label="@string/app_name"`,
et chaque saveur nomme son application par un fichier de ressources. Sans cela,
les deux icônes seraient indiscernables sur l'écran d'accueil de l'auteur.

Ces libellés ont d'abord été écrits en `resValue()` dans `build.gradle.kts`.
**AGP 9 désactive cette fonctionnalité par défaut** et refuse alors de configurer
le projet (« Product Flavor jeu contains custom resource values, but the feature
is disabled »). Plutôt que de rallumer un drapeau que les versions suivantes
d'AGP éteindront encore, les libellés sont de vraies ressources : le recouvrement
par saveur est le mécanisme Android le plus ancien et le plus stable, et un
libellé d'application **est** une ressource. Le test refuse désormais tout
`resValue(` dans le fichier de build.

## Construire

Les commandes de lancement des deux saveurs sont dans **`Commandes.md`**, avec ce
qu'elles exigent et les garde-fous qui couvrent l'appariement `--flavor` / `-t`.
Elles ne sont pas répétées ici : deux descriptions du même geste finiraient par
diverger.

## Quatre couches à ne pas confondre

Ces noms n'ont ni la même portée ni le même coût de changement.

**L'identifiant Android** (`fr.naryabordeaux.grisbie`) est une identité
technique, jamais vue de l'utilisateur. C'est **le seul élément irréversible** :
le Play Store ne permet aucun changement après la première publication. Une
autre valeur serait une autre application, sans ses installations ni ses avis.

**Le libellé sous l'icône** (`Grisbie`) est ce que l'enfant lit sur l'écran
d'accueil. Court par nécessité : l'écran d'accueil tronque au-delà d'une douzaine
de caractères.

**Le nom de la fiche Play Store** (`Les Aventures de Grisbie`, 24 caractères sur
les 30 autorisés) se saisit dans la console. Il ne figure nulle part dans le
dépôt, et se change quand on veut.

**Le package Dart** (`grisbie`) est purement interne. Il n'apparaît que dans les
imports, et son changement n'a aucun effet visible.

Le titre d'application, lui, est un cas à part : `MaterialApp.title` sert
d'étiquette dans le sélecteur d'applications Android et de titre d'onglet sur le
Web. Il reprend le nom de la fiche, jamais le libellé court.

## Firebase — un tuyau d'auteur, pas un service du jeu

**Le produit retenu est Cloud Storage**, pas Firestore : l'outil d'auteur y
dépose le contenu écrit sur le téléphone, on le relit depuis le poste, et il
finit commité dans `assets/content/` comme aujourd'hui. Le choix répond au fait
qu'un fichier écrit sur un téléphone est difficile à rapatrier.

**Le jeu livré ne contacte rien.** Le public étant mineur, aucune donnée ne sort
de l'appareil.

### Un seul projet, et c'est délibéré

`grisbie-43ee9` — l'identifiant porte un suffixe parce que Firebase les veut
uniques au monde ; il est **définitif**.

Deux projets, un de développement et un de production, ont été prévus puis
écartés. Ce que dev/prod sépare d'ordinaire, ce sont les données réelles des
utilisateurs pendant qu'on expérimente : **ici il n'y a ni utilisateurs ni
données**. Le bucket est un tuyau entre le poste et le téléphone, et la
production de ce projet n'est pas Firebase mais le dépôt git et la fiche Play
Store.

Le second projet coûtait plus qu'il ne protégeait : chaque lancement porte six
valeurs, et deux jeux de six augmentent surtout le risque de déposer dans le
mauvais bucket. Ce qu'on y perdrait au pire, c'est le travail non encore
commité — et l'outil enregistre aussi en local, donc le bucket n'est jamais la
seule copie.

**La décision est réversible pour rien** : les valeurs arrivent au lancement,
créer un second projet plus tard se résume à changer une ligne de commande. Le
jour où l'écriture d'aventures s'ouvrirait à quelqu'un d'autre — le dépôt part
en open source — c'est ce jour-là qu'il faudra y revenir.

### L'application enregistrée porte l'identifiant de l'outil

`fr.naryabordeaux.grisbie.auteur`, jamais celui du jeu : Firebase apparie sur
l'`applicationId` exact. Conséquence recherchée — l'identifiant publié n'existe
dans aucun projet Firebase, et une configuration égarée n'y correspondrait de
toute façon pas.

L'outil d'auteur tournant aussi dans un navigateur, une application **Web** doit
être enregistrée dans le même projet, avec ses propres valeurs.

### La règle qui protège le jeu des enfants

Sur Android, le SDK Firebase **s'initialise tout seul** dès que
`google-services.json` est présent au build, et enregistre un identifiant
d'appareil auprès de Google. Or les deux points d'entrée, `lib/main.dart` et
`lib/main_author.dart`, partagent le même `pubspec.yaml` et le même dossier
`android/`.

**Ce fichier n'existe donc pas.** Depuis 0.23.0, les valeurs du projet arrivent
par `--dart-define` au lancement et `Firebase.initializeApp` reçoit des
`FirebaseOptions` explicites. Rien ne déclenche l'initialisation automatique :
le jeu **ne peut pas** contacter Firebase, même par mégarde.

C'est une garantie plus forte que celle que les saveurs donnaient, et elle est
vérifiée — `author_only_test.dart` exige qu'un seul fichier du dépôt appelle
`Firebase.initializeApp`, et que rien hors de `lib/infrastructure/remote/`
n'importe Firebase.

Rien de ces valeurs n'entre dans le dépôt, qui se compile sans elles : absentes,
l'outil enregistre en local et ne propose pas la connexion.

Les saveurs subsistent, mais ne portent plus rien de Firebase. Ce qu'elles
séparent désormais : l'identifiant et le libellé du **paquet Android**, ce qui
fait cohabiter les deux applications sur le téléphone et rend impubliable un jeu
construit par erreur avec la saveur auteur.

### La connexion de l'auteur

Par **e-mail et mot de passe**, pas par Google : Google sur Android exige
d'enregistrer les empreintes SHA-1 de chaque magasin de clés, ce qui marche en
debug et casse en release. L'e-mail se comporte à l'identique sur le web et sur
un téléphone, sans greffon de plus.

Un seul compte, créé à la main dans la console. La règle du bucket nomme son
**UID** — jamais son adresse, le dépôt partant en open source — et l'outil
affiche cet UID une fois connecté, pour qu'on puisse le recopier.

## Signature de l'application publiée

La clé de signature et ses mots de passe n'entrent jamais dans le dépôt :
`android/key.properties` et les magasins de clés (`*.jks`, `*.keystore`) sont
ignorés par git. Le modèle des quatre lignes attendues est dans
`android/key.properties.example`, avec la commande de création.

Fichier absent — session cloud, poste d'un contributeur — le build retombe sur
la clé de debug. Le paquet s'installe alors sur un appareil, mais **ne peut pas
être publié**.

Cette clé est irremplaçable : la perdre interdit toute mise à jour de
l'application publiée, à moins d'avoir activé la signature par Google Play.

## Ce qui reste à faire en console

Ces points ne sont pas réalisables depuis le dépôt. Ils sont suivis dans
`TODO.md`.

Le jeu s'adressant à des enfants de 6 à 7 ans, la publication relève de la
politique **Families** de Google Play, qui impose au minimum :

- une déclaration d'audience cible « enfants », qui engage sur le reste ;
- une **politique de confidentialité en ligne**, obligatoire et sans exception ;
- le formulaire « sécurité des données », à remplir ;
- aucune régie publicitaire non certifiée.

Le fait qu'aucune donnée ne quitte l'appareil rend ce formulaire simple à
remplir — et honnête. C'est la contrepartie directe de la décision « pas de
serveur », et la raison pour laquelle `google-services.json` ne doit pas dériver
dans la saveur du jeu.

Restent également, hors politique : l'icône de l'application, encore celle du
modèle Flutter, les captures d'écran, le visuel de la fiche, et la classification
du contenu.
