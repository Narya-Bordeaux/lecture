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
| Nom sous l'icône | **Grisbie** | `android:label`, `android/app/src/main/AndroidManifest.xml` |
| Identifiant Android **définitif** | `fr.naryabordeaux.grisbie` | `applicationId` et `namespace`, `android/app/build.gradle.kts` |
| Paquet Kotlin | `fr.naryabordeaux.grisbie` | `android/app/src/main/kotlin/fr/naryabordeaux/grisbie/` |
| Package Dart interne | `grisbie` | `pubspec.yaml`, et tous les `import 'package:grisbie/…'` |
| Titre de l'application | Les Aventures de Grisbie | `UiStringsFr.appTitle` |
| Projet Firebase développement | `narya-grisbie-dev` | console Firebase |
| Projet Firebase production | `narya-grisbie-prod` | console Firebase |
| Pseudo de l'app Android dans Firebase | Les Aventures de Grisbie – Android | console Firebase |

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

L'application Android enregistrée dans les deux projets Firebase porte
l'identifiant du jeu, `fr.naryabordeaux.grisbie` — Firebase apparie sur
l'`applicationId` exact.

### La règle qui protège le jeu des enfants

Sur Android, le SDK Firebase **s'initialise tout seul** dès que
`google-services.json` est présent au build, et enregistre un identifiant
d'appareil auprès de Google. Or les deux points d'entrée, `lib/main.dart` et
`lib/main_author.dart`, partagent le même `pubspec.yaml` et le même dossier
`android/`.

Tant qu'aucune saveur Gradle ne les sépare, **ce fichier ne doit exister nulle
part dans le dépôt** : le jeu des enfants l'embarquerait mécaniquement.
`android_packaging_test.dart` échoue s'il apparaît.

Il n'est volontairement pas listé dans `.gitignore` : ignoré, il serait présent
au build sans que rien ne le signale, et c'est précisément le scénario à éviter.
Un test qui échoue en nommant la raison vaut mieux qu'un fichier invisible.

Le jour où une saveur « auteur » existera, ce test devra n'autoriser que son
dossier — et non être supprimé.

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
