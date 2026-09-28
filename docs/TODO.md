# TODO

Liste unique et courte de ce qui reste à faire. Ce qui est fait disparaît d'ici et
n'existe plus que dans `versions.md`.

## Pages de récit, images et dépôt — en discussion avec l'auteur

- [ ] **Éprouver le choix d'une image dans Chrome et sur le téléphone** —
      les noms portent des espaces et des accents (`Grisbie forêt.jpg`) :
      les tests les lisent, aucun navigateur ne l'a encore fait.
- [ ] **La page de récit**, type de page à part (titre, illustration, texte,
      une seule suite, ou marquée fin) : page de garde, transition, fin. Le
      type se choisit à la création de la page.

## Plus tard — décidé, pas encore le moment

- [ ] **Un aperçu multi-formats dans l'outil** : la scène dans deux ou trois
      cadres de téléphone (360×640, 390×844, tablette) sur l'ordinateur,
      pour attraper sans téléphone un énoncé trop long ou une zone trop
      petite. Ne remplace pas l'essai au doigt.

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

## Avant publication sur le Play Store

Les noms sont fixés et vérifiés par test. Ce qui reste ne se fait pas depuis le
dépôt — voir `Noms_et_identifiants.md` pour le détail.

- [ ] **Créer la clé de signature** et renseigner `android/key.properties`
      d'après le modèle `key.properties.example`. Clé irremplaçable : la perdre
      interdit toute mise à jour de l'application publiée.
- [ ] **Dessiner l'icône** : c'est encore celle du modèle Flutter.
- [ ] Déclarer l'audience cible « enfants » — le jeu relève de la politique
      *Families* de Google Play, qui engage sur tout le reste.
- [ ] **Rédiger et héberger une politique de confidentialité** : obligatoire et
      sans exception pour cette audience, même si l'application n'émet rien.
- [ ] Remplir le formulaire « sécurité des données ». Aucune donnée ne quittant
      l'appareil, il est simple à remplir — à condition que ce soit toujours
      vrai au moment de la publication.
- [ ] Captures d'écran, visuel de fiche, classification du contenu.
- [ ] Saisir le nom de la fiche : **Les Aventures de Grisbie**. Il ne figure pas
      dans le dépôt.

## Avant publication en open source

- [ ] Étoffer le `README.md` : à qui s'adresse le jeu, ce qu'il apprend, comment le
      lancer.

## Conception

- [ ] Répondre aux questions ouvertes de la spécification (déclenchement et ordre des
      aides, forme de la carte, contenu d'une étape, niveaux, suivi des progrès).

## Développement

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
- [ ] **Étendre la zone manquante aux lieux sans illustration.** Depuis
      0.30.0, une famille sans zone est signalée *à finir*, mais seulement sur
      un lieu illustré : la gare et la boutique livrées n'ont ni décor ni
      zones, et le jeu, qui refuse toute anomalie, ne s'ouvrirait plus. À
      reprendre une fois ces deux lieux illustrés et calés.
- [ ] Écrire les six thèmes proposés : station-service et garage (en voiture),
      marché et école (en bus), loueur de vélos et forêt (à pied).
- [ ] **Étoffer les listes livrées et poser leur `drawCount`.** Depuis 0.17.0
      une liste peut être plus grande que la partie, ce qui fait varier les
      mots d'une partie à l'autre — mais les sept listes livrées font encore
      exactement la taille jouée, et ne tirent donc rien. C'est du vocabulaire
      à écrire.
- [ ] **Une liste d'objets hétéroclites, commune à tous les tris uniques.**
      `objets_divers` existe déjà pour la boutique ; l'exclusion par lieu
      permet de la partager, chaque tri unique en retranchant son thème.
- [ ] Persistance locale de la progression (aucune donnée ne quitte l'appareil).
- [ ] Orientation : le jeu est verrouillé en portrait, décidé pour le MVP.
