# Saveur « auteur »

Ce dossier est le **seul endroit** du dépôt où `google-services.json` a le droit
d'exister. `test/infrastructure/android_packaging_test.dart` le refuse partout
ailleurs.

Raison : sur Android, le SDK Firebase s'initialise tout seul dès que ce fichier
est présent au build, et enregistre un identifiant d'appareil auprès de Google.
Les deux points d'entrée du projet partagent le même dossier `android/` ; sans
cette séparation, le jeu livré à des enfants de 6-7 ans embarquerait la
configuration Firebase de l'outil d'auteur et contacterait un serveur.

## Le fichier à déposer ici

`google-services.json`, téléchargé depuis la console Firebase pour l'application
Android enregistrée sous **`fr.naryabordeaux.grisbie.auteur`** — l'identifiant du
jeu suffixé, jamais celui du jeu seul. Firebase apparie sur l'`applicationId`
exact : un fichier téléchargé pour un autre identifiant ne fonctionnera pas.

Il est ignoré par git : le dépôt est destiné à l'open source, et ce fichier
désigne le projet Firebase de l'auteur avec ses clés.

## Basculer entre les deux projets

Une seule saveur auteur existe. Pour passer de `narya-grisbie-dev` à
`narya-grisbie-prod`, remplacer le fichier à la main. Si la confusion arrive un
jour, c'est le signal qu'il faut découper cette saveur en deux.

## Construire

Une saveur ne choisit **pas** le point d'entrée Dart : les deux options sont
indépendantes et doivent être appariées.

```bash
flutter run --flavor auteur -t lib/main_author.dart
```

`lib/main_author.dart` refuse de démarrer si la saveur n'est pas celle-ci.

Les fichiers de ce dossier qui ne sont ni dans `res/`, ni dans `kotlin/`, ni dans
`assets/` — ce README compris — sont ignorés par le système de build Android.
