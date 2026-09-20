# TODO

Liste unique et courte de ce qui reste à faire. Ce qui est fait disparaît d'ici et
n'existe plus que dans `versions.md`.

## Cadre de travail

- [ ] Installer Flutter dans l'environnement cloud via un hook de démarrage de
      session, pour y rendre possibles `flutter analyze` et `flutter test`.
- [ ] Décider du sort du dossier `ios/` : iOS n'est pas une plateforme visée, mais
      27 des fichiers suivis lui appartiennent.
- [ ] Ajouter les cibles Web et Windows (`flutter create --platforms=web,windows .`),
      à lancer depuis le poste de développement.

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
