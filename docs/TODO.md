# TODO

Liste unique et courte de ce qui reste à faire. Ce qui est fait disparaît d'ici et
n'existe plus que dans `versions.md`.

## Cadre de travail

- [ ] Installer Flutter dans l'environnement cloud via un hook de démarrage de
      session, pour y rendre possibles `flutter analyze` et `flutter test`.
- [ ] Ajouter les cibles Web et Windows, depuis le poste de développement :
      `flutter create --platforms=web,windows --org fr.naryabordeaux .`

## Si un jour iOS revient au programme

Le dossier `ios/` a été supprimé en 0.1.1 : plateforme non visée, aucun compte
Apple, et 27 fichiers générés sur les 69 que suivait le dépôt. Rien n'y avait été
personnalisé. Pour le régénérer à l'identique, une seule commande suffit :

```bash
flutter create --platforms=ios --org fr.naryabordeaux .
```

Mieux vaut la relancer que récupérer l'ancienne version dans l'historique git : les
fichiers de projet Xcode évoluent à chaque version de Flutter, un squelette conservé
trop longtemps serait de toute façon périmé.

## Avant publication en open source

- [ ] Remplacer la description générée `"A new Flutter project."` dans
      `pubspec.yaml`.
- [ ] Étoffer le `README.md` : à qui s'adresse le jeu, ce qu'il apprend, comment le
      lancer.

## Conception

- [ ] Répondre aux questions ouvertes de la spécification (déclenchement et ordre des
      aides, forme de la carte, contenu d'une étape, niveaux, suivi des progrès).
- [ ] Définir le format JSON du contenu pédagogique dans `assets/content/`.

## Développement

- [ ] Écrire les modèles du domaine : mot, famille, étape, niveau, parcours.
- [ ] Écrire le moteur d'une étape en TDD : tirage des mots, validation d'un
      classement, comptage des erreurs, déclenchement des aides, fin d'étape.
- [ ] Remplacer le squelette de `lib/main.dart` et le test de démonstration.
