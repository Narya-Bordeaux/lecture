# Commandes

Ce que l'on tape pour lancer, vérifier et construire le projet. Une commande
n'entre ici que le jour où elle a réellement été exécutée avec succès — ce
document n'est pas une liste d'intentions.

Chaque commande est donnée avec ce qu'elle exige et ce qu'elle produit, parce
qu'une commande sans son contexte finit par être recopiée au mauvais endroit.

## Lancer

**Une saveur Gradle ne choisit pas le point d'entrée Dart.** `--flavor` et `-t`
sont deux options indépendantes, que rien n'oblige à apparier. Elles vont
toujours ensemble, dans ces deux combinaisons et pas d'autres :

```bash
# Le jeu, celui qui sera publié
flutter run --flavor jeu -t lib/main.dart

# L'outil d'auteur, qui cale les zones sur l'illustration
flutter run --flavor auteur -t lib/main_author.dart
```

**Exige** : un poste équipé du SDK Android et un appareil ou un émulateur
connecté. Ces commandes ne fonctionnent pas en session cloud, faute de SDK.

**Produit** : deux applications distinctes, qui cohabitent sur l'appareil —
« Grisbie » et « Grisbie auteur ». L'outil d'auteur porte l'identifiant suffixé
`fr.naryabordeaux.grisbie.auteur` ; voir `Noms_et_identifiants.md`.

Les saveurs existant, **`--flavor` est obligatoire** : `flutter run` ou
`flutter build` sans elle s'arrête en le disant.

Deux garde-fous couvrent l'appariement, chacun dans un sens. `lib/main_author.dart`
vérifie au démarrage la constante `appFlavor` et refuse de s'ouvrir sous la
saveur du jeu, où il n'aurait pas sa configuration Firebase et aurait échoué plus
tard et plus loin. Dans l'autre sens, celui qui compte, le suffixe suffit : un jeu
compilé par erreur sous la saveur auteur ne porte pas l'identifiant publié, il est
donc impubliable et l'erreur reste sans conséquence.

## Vérifier

```bash
flutter analyze
flutter test
```

**Exige** : rien de plus que le SDK Flutter. Ces deux commandes ne passent pas
par Gradle, ignorent donc les saveurs, et **fonctionnent en session cloud**.

À lancer après toute modification de code. Elles prouvent le comportement du
moteur et la forme des fichiers de configuration ; elles ne prouvent pas que le
projet Android compile — seul un `flutter run` le dit.

Séparation moteur / interface, la règle structurante du projet :

```bash
grep -rn "package:flutter/" lib/domain lib/application && echo "VIOLATION" || echo "OK"
```

## Ce que ce document ne couvre pas encore

Rien n'est écrit ici sur la construction d'un paquet publiable, la signature, ni
la mise en ligne : ces gestes n'ont jamais été faits. Ils seront ajoutés le jour
où ils auront abouti, pas avant. Ce qui reste à faire est dans `TODO.md`.
