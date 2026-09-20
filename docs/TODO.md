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
- [ ] Trancher le **tirage** : il est libre, donc aucun mot d'une famille donnée
      peut n'être à l'écran. Faut-il garantir au moins un mot par famille ?
- [ ] Vérifier à l'usage que la fin d'étape ne devient pas trop facile : deux
      familles pleines, et les derniers mots se classent sans être lus. C'est le
      revers assumé de l'aide par réduction du choix.
- [ ] `abri` reste vague hors du contexte de l'abribus, et `talon` côtoie
      `ticket` dans la même étape (un ticket a un talon). À revoir si l'usage
      montre une hésitation.
- [ ] Illustrer les autres étapes : la gare et la boutique n'ont ni décor ni
      zones placées, elles s'affichent sur fond uni.
- [ ] Écrire les six thèmes proposés : station-service et garage (en voiture),
      marché et école (en bus), loueur de vélos et forêt (à pied).
- [ ] Nommer le second classeur d'une énigme. « Laisse-le » est un tri par
      rejet ; deux gestes positifs seraient peut-être plus justes à six ans.
- [ ] Persistance locale de la progression (aucune donnée ne quitte l'appareil).
- [ ] Orientation : le jeu est verrouillé en portrait, décidé pour le MVP.
- [ ] Portraits des personnages : `portrait` existe dans le format mais aucun
      dessin n'est fourni ; seul le nom s'affiche.
