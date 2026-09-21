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

L'authentification est tranchée : **un compte Google unique, celui de l'auteur**.
L'usage est solo, personne d'autre n'a de contenu à déposer.

Dans cet ordre, qui compte — le bucket s'ouvre en écriture par défaut :

- [ ] Créer `narya-grisbie-dev`, et y enregistrer l'application Android sous
      `fr.naryabordeaux.grisbie.auteur`.
- [ ] Activer Cloud Storage et **poser immédiatement une règle qui refuse
      tout** — avant même de savoir à qui on ouvrira. Un bucket ouvert n'a pas
      besoin d'être connu pour être trouvé.

      ```
      rules_version = '2';
      service firebase.storage {
        match /b/{bucket}/o {
          match /{allPaths=**} {
            allow read, write: if false;
          }
        }
      }
      ```

- [ ] Activer le fournisseur **Google** dans Authentication, puis s'y connecter
      une première fois : l'UID n'existe pas avant. Il apparaît ensuite dans
      Authentication › Users.
- [ ] Remplacer la règle par celle-ci, l'UID collé en clair. **Ne pas y mettre
      d'adresse e-mail** : ce dépôt part en open source, et un UID ne désigne
      personne hors du projet.

      ```
      rules_version = '2';
      service firebase.storage {
        match /b/{bucket}/o {
          // Seul l'auteur depose et relit. Le jeu livre aux enfants ne
          // contacte pas Firebase : rien d'autre n'a affaire ici.
          match /{allPaths=**} {
            allow read, write: if request.auth != null
                && request.auth.uid == 'UID_DE_L_AUTEUR';
          }
        }
      }
      ```

- [ ] Déposer `google-services.json` dans `android/app/src/auteur/`, et nulle
      part ailleurs — `android_packaging_test.dart` le refuse ailleurs. Il est
      ignoré par git : c'est voulu, il porte les clés du projet de l'auteur.
- [ ] `narya-grisbie-prod` plus tard, à l'identique. Une seule saveur auteur
      existe, donc un seul `google-services.json` à la fois : on bascule en
      remplaçant le fichier.
- [ ] Vérifier **sur l'appareil** que le jeu ne contacte rien, plutôt que de le
      supposer. Les saveurs le rendent structurellement improbable, elles ne le
      démontrent pas.

**Faisable en session cloud, et ne dépend pas de Firebase** :

L'étape 3 est largement faite : `OutlinePage` construit le parcours, les
anomalies s'affichent classées. Deux manques restent, découverts en la
construisant :

- [ ] **Enregistrer.** `OutlinePage` travaille en mémoire et rend l'aventure
      modifiée à l'appelant ; personne ne l'écrit. `ContentWriter` et
      `FileContentSink` existent — il manque le geste et le dossier où écrire.
- [ ] **Passer l'outil à `loadDraft`.** `AuthorHomePage` charge encore par
      `loadAdventure`, qui refuse toute aventure incomplète : dès qu'un
      brouillon sera enregistré, l'outil ne pourra plus le rouvrir.
- [ ] Saisir les **récits** d'arrivée et de départ d'un lieu, et la réplique
      d'un personnage — l'écran ne les demande pas encore.
- [ ] **Rouvrir une fin créée par erreur.** Depuis 0.18.0 une carte de fin n'a
      plus de bouton « Ajouter des trajets » : c'est juste, mais cela en fait
      un cul-de-sac dans l'outil. `AdventureBuilder` sait pourtant prolonger
      une fin ; il manque le geste, sans doute ailleurs que sur cette carte.

**La navigation visée depuis l'écran du parcours** — discutée, pas encore
arbitrée en détail. Elle absorbe les étapes 4 à 6 du chantier :

- [ ] **Vérifier le choix d'image sur l'appareil.** Fait depuis 0.20.0, mais
      **jamais exécuté** : ni `image_picker` ni `path_provider` ne tournent en
      session cloud. À éprouver sur le téléphone — le Photo Picker s'ouvre-t-il
      sans demander de permission, la copie survit-elle, l'aperçu s'affiche-t-il.
- [ ] **Rapatrier les images de travail.** Une image choisie sur le téléphone
      vit dans le dossier de l'application ; elle doit finir dans
      `assets/pictures/` du dépôt. Le chemin stocké devra être réécrit au
      passage. C'est le même manque que l'enregistrement du contenu, et sans
      doute le même geste.
- [ ] **Cliquer un trajet dans une carte** ouvre la liste de mots de cette
      famille : saisie des mots et de leur découpage, unicité d'orthographe
      garantie (étape 5). Depuis 0.17.0 c'est une `WordList` qu'on édite, et
      elle peut être citée ailleurs : l'écran devra dire quand une liste sert à
      plusieurs lieux, sous peine de la modifier à l'insu de l'autre.
- [ ] **Un bouton « Valider »**, à gauche d'« Ajouter », qui valide les listes.
      Reste à définir ce que « valider » arrête exactement — figer une liste
      close, ou seulement signaler qu'on la considère finie.

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
- [ ] **Étoffer les listes livrées et poser leur `drawCount`.** Depuis 0.17.0
      une liste peut être plus grande que la partie, ce qui fait varier les
      mots d'une partie à l'autre — mais les sept listes livrées font encore
      exactement la taille jouée, et ne tirent donc rien. C'est du vocabulaire
      à écrire, avec son découpage.
- [ ] **Une liste d'objets hétéroclites, commune à tous les tris uniques.**
      `objets_divers` existe déjà pour la boutique ; l'exclusion par lieu
      permet de la partager, chaque tri unique en retranchant son thème.
- [ ] Nommer la **liste du reste** d'un tri unique. L'outil propose
      « Le reste » ; le contenu livré dit « Laisse-le ». Les deux sont des tris
      par rejet, et deux gestes positifs seraient peut-être plus justes à six
      ans.
- [ ] Persistance locale de la progression (aucune donnée ne quitte l'appareil).
- [ ] Orientation : le jeu est verrouillé en portrait, décidé pour le MVP.
- [ ] Portraits des personnages : `portrait` existe dans le format mais aucun
      dessin n'est fourni ; seul le nom s'affiche.
