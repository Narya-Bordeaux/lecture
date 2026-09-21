# TODO

Liste unique et courte de ce qui reste à faire. Ce qui est fait disparaît d'ici et
n'existe plus que dans `versions.md`.

## Outil de création d'une journée

Le chantier en cours, décrit dans `current.md`. Les étapes 1 et 2 sont faites.

**À faire hors session cloud — ces points ne sont pas testables ici** (ni SDK
Android, ni appareil, ni accès à votre console) :

Les noms sont fixés par `Noms_et_identifiants.md` : projets `narya-grisbie-dev`
et `narya-grisbie-prod`, application Android enregistrée sous
`fr.naryabordeaux.grisbie.auteur` — **l'identifiant suffixé de l'outil, pas celui
du jeu**. Le produit retenu est **Cloud Storage**, pas Firestore. Les saveurs
Android existent depuis 0.9.4 et **les deux builds tournent sur le poste** ;
`android/app/src/auteur/` attend le fichier.

- [ ] Créer les deux projets Firebase et y enregistrer l'application Android.
- [ ] Activer Cloud Storage et **écrire les règles de sécurité tout de suite** :
      le bucket s'ouvre par défaut pour quelques semaines. Personne d'autre que
      l'auteur n'y écrit, donc refuser tout accès anonyme est le bon réglage.
- [ ] Trancher l'authentification : sans elle, le bucket est soit ouvert en
      écriture — à exclure — soit inaccessible. Un compte Google unique, celui de
      l'auteur, suffit pour un usage solo.
- [ ] Déposer `google-services.json` dans `android/app/src/auteur/`, et nulle
      part ailleurs — `android_packaging_test.dart` le refuse ailleurs. Il est
      ignoré par git : c'est voulu, il porte les clés du projet de l'auteur.
- [ ] Vérifier **sur l'appareil** que le jeu ne contacte rien, plutôt que de le
      supposer. Les saveurs le rendent structurellement improbable, elles ne le
      démontrent pas.

**Faisable en session cloud, et ne dépend pas de Firebase** :

- [ ] Étape 3 : éditer textes et structure — lieux, récits, familles,
      destinations, avec les erreurs signalées en direct (destination fantôme,
      lieu inatteignable, cul-de-sac). `Adventure.validate()` sait déjà les
      trouver, il reste à les montrer pendant l'édition.
- [ ] Étape 4 : l'image. Pendant l'édition elle doit se charger **par chemin de
      fichier**, les assets étant scellés au build ; `BackgroundImageSize` devra
      savoir faire les deux.
- [ ] Étape 5 : le lexique — saisie des mots et de leur découpage, unicité
      d'orthographe garantie.
- [ ] Étape 6 : rebrancher le calage des zones sur l'aventure éditée, et
      enregistrer au lieu de copier dans le presse-papiers.

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
- [ ] Écrire les six thèmes proposés : station-service et garage (en voiture),
      marché et école (en bus), loueur de vélos et forêt (à pied).
- [ ] Nommer le second classeur d'une énigme. « Laisse-le » est un tri par
      rejet ; deux gestes positifs seraient peut-être plus justes à six ans.
- [ ] Persistance locale de la progression (aucune donnée ne quitte l'appareil).
- [ ] Orientation : le jeu est verrouillé en portrait, décidé pour le MVP.
- [ ] Portraits des personnages : `portrait` existe dans le format mais aucun
      dessin n'est fourni ; seul le nom s'affiche.
