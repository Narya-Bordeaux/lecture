# TODO

Liste unique et courte de ce qui reste à faire. Ce qui est fait disparaît d'ici et
n'existe plus que dans `versions.md`.

## Outil de création d'une journée

Le chantier en cours, décrit dans `current.md`. Les étapes 1 et 2 sont faites.

**À faire dans votre console — ces points ne sont pas testables ici** :

Les noms sont fixés par `Noms_et_identifiants.md` : **un seul projet**,
`grisbie-43ee9`, et c'est délibéré — il n'y a ni utilisateurs ni données à
protéger d'un environnement de test. Le produit retenu est **Cloud Storage**,
pas Firestore.

Deux choses ont changé en 0.23.0, et allègent beaucoup cette liste :

- **Pas de `google-services.json`.** Le greffon Gradle qui le lit échoue quand
  le fichier manque, ce qui aurait cassé la saveur `jeu`. Les valeurs passent
  par `--dart-define` au lancement. Rien à déposer dans le dépôt, rien à
  ignorer par git — et l'auto-initialisation d'Android n'existe plus du tout.
- **Connexion par e-mail et mot de passe**, pas par Google. Google sur Android
  exige d'enregistrer les empreintes SHA-1 des magasins de clés : ça marche en
  debug et ça casse en release. L'e-mail se comporte à l'identique partout.

Dans cet ordre, qui compte — le bucket s'ouvre en écriture par défaut :

- [x] Créer le projet. C'est `grisbie-43ee9` — Firebase suffixe les
      identifiants, qu'il veut uniques au monde, et celui-ci est définitif.
- [x] **Activer Cloud Storage.** Fait. Le bucket est
      `grisbie-43ee9.firebasestorage.app`, ce que `Commandes.md` dit déjà.
      Le passage au plan **Blaze** était attendu ici — un projet neuf ne
      provisionne plus de bucket sur Spark — et ne s'est pas avéré bloquant.
- [x] **Poser une règle qui refuse tout**, avant même de savoir à qui on
      ouvrira — un bucket ouvert n'a pas besoin d'être connu pour être trouvé.
      Rien à faire : **Firebase la pose désormais par défaut**, et c'est bien
      celle-ci qu'on lit dans l'onglet Règles d'un projet neuf.

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

- [ ] Dans Authentication, activer le fournisseur **E-mail/Mot de passe**, puis
      **créer le compte de l'auteur à la main** (Users › Add user). Son UID
      apparaît aussitôt dans la liste.
- [ ] **Remplacer la règle** par celle-ci, l'UID collé en clair. Tant que la
      règle par défaut tient, se connecter réussira et le dépôt échouera :
      `if false` refuse aussi l'auteur. **Ne pas y mettre
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

- [x] Enregistrer une application **Web** dans le projet, et relever les six
      valeurs de sa configuration. Fait. Le SDK JavaScript que la console
      propose ne concerne pas Flutter : seules les six valeurs comptent, et
      elles se passent au lancement — commande complète dans `Commandes.md`.
- [ ] Vérifier que l'application **Android** déjà déclarée porte
      `fr.naryabordeaux.grisbie.auteur` — **jamais** l'identifiant du jeu, qui
      ne doit exister dans aucun projet Firebase. Elle a ses six valeurs à
      elle : l'`appId` diffère d'une application à l'autre.
- [x] Relever le **nom exact du bucket** : `grisbie-43ee9.firebasestorage.app`.
- [ ] **Lancer l'outil avec ces valeurs, et vérifier que tout marche.** Rien
      n'a jamais été exécuté : ni la connexion, ni le dépôt d'un fichier, ni
      sa relecture. L'outil affiche l'UID une fois connecté — c'est celui que
      la règle doit nommer, à comparer. **Piège attendu** : tant que la règle
      par défaut tient, la connexion réussit et le dépôt échoue.
- [ ] **Attendu dans un navigateur : le CORS.** La lecture du bucket depuis
      Chrome est une requête soumise au contrôle d'origine, et un bucket neuf
      n'a pas de politique. L'écriture passerait et la relecture échouerait,
      sans rapport visible avec la cause. Se règle depuis le Cloud Shell de la
      console. Sur le téléphone, la question ne se pose pas.
- [ ] Vérifier **sur l'appareil** que le jeu ne contacte rien, plutôt que de le
      supposer. `author_only_test.dart` le rend structurellement improbable —
      rien n'initialise Firebase hors de l'outil — mais ne le démontre pas.

**Faisable en session cloud, et ne dépend pas de Firebase** :

L'étape 3 est largement faite : `OutlinePage` construit le parcours, les
anomalies s'affichent classées. Deux manques restent, découverts en la
construisant :

- [ ] **Éprouver l'aller-retour pour de vrai.** Enregistrer puis rouvrir est
      fait — 0.22.0 pour l'écriture, 0.24.0 pour la relecture — et éprouvé sur
      un dossier en mémoire, mais **jamais exécuté** : ni sur l'appareil
      (dossier des documents), ni dans un navigateur (téléchargement, qui ne
      se relit pas). À vérifier sur le poste et sur le téléphone.
- [ ] **Rapatrier le dossier écrit vers le dépôt.** Sur l'appareil il vit dans
      les documents de l'application ; dans un navigateur il descend en
      fichiers séparés au nom aplati. Les deux se reposent à la main dans
      `assets/content/`. C'est ce qu'un dépôt distant remplacera.
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
- [ ] **Ouvrir l'outil d'auteur dans Chrome, pour de vrai.** Les deux points
      d'entrée *compilent* pour le web depuis 0.21.0, ce qui ne prouve que
      l'absence d'import interdit. Restent à éprouver : le chargement du
      contenu depuis les assets, le glisser-déposer des mots à la souris, et
      le calage des zones sur un grand écran. `flutter run -d chrome -t
      lib/main_author.dart` depuis le poste.
- [ ] Ajouter la cible Windows, depuis le poste de développement :
      `flutter create --platforms=windows --org fr.naryabordeaux .`

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
