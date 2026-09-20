# TODO

Liste unique et courte de ce qui reste à faire. Ce qui est fait disparaît d'ici et
n'existe plus que dans `versions.md`.

## Cadre de travail

- [ ] Aligner le SDK du poste de développement sur la version épinglée par le hook
      (Flutter 3.47.5), faute de quoi `pubspec.lock` fera des allers-retours entre
      le poste et les sessions cloud.
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

- [ ] **Juger le rendu réel sur appareil** : le jeu n'a jamais été vu à l'écran,
      aucun build n'étant possible en session cloud. Position des trois zones,
      taille des étiquettes, lisibilité sur le décor.
- [ ] Trancher l'**objectif** par famille, fixé à 5 sur 10 mots. Combien de mots
      un enfant doit-il classer pour ouvrir un chemin ?
- [ ] Trancher le **tirage** : il est libre, donc aucun mot d'une famille donnée
      peut n'être à l'écran. Faut-il garantir au moins un mot par famille ?
- [ ] Relire les trois listes de dix mots. Quelques-uns valent pour le bus comme
      pour la voiture — `ceinture`, `phare`, `pneu` — et `abri` est vague hors du
      contexte de l'abribus.
- [ ] Illustrer les autres étapes : la gare n'a ni décor ni zones placées, elle
      s'affiche sur fond uni.
- [ ] Persistance locale de la progression (aucune donnée ne quitte l'appareil).
- [ ] Illustrations des mots : le champ `illustrationAsset` existe et reste vide.
      Tant qu'il l'est, l'aide « illustration » n'a rien à montrer, alors qu'elle
      se débloque à la 5ᵉ erreur.
- [ ] Orientation : le jeu est verrouillé en portrait, décidé pour le MVP.
- [ ] Récit : `Stage.narrative` n'est affiché que sur les étapes terminales.
