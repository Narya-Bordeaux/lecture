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
- [ ] **Images illisibles dans l'outil, connecté au dépôt** (vu par
      l'auteur dans Chrome, le 24 septembre) : les vignettes et l'aperçu
      échouent alors que le jeu montre les images. Non reproduit : dans
      Chromium, en mode local, debug comme release, tout s'affiche. La raison
      s'affiche désormais dans l'outil — la relever.
- [ ] **Éprouver l'accueil au doigt, sur le téléphone** (0.45.0) : vu
      seulement en capture. À juger : la taille des vignettes (≈ 90 points de
      large sur un téléphone courant), la lecture des titres penchés, le
      vide entre le logo et la roue, le geste de rotation.
- [ ] **Éprouver la mise en place d'un lieu au doigt** (0.46.0) : vue
      seulement en capture. À juger : la durée du décor seul, la boîte
      agrandie (translucide comme la zone) sur un décor chargé, la vitesse
      de l'envol, et si toucher n'importe où pour ranger la boîte convient.
- [ ] **Éprouver le geste au doigt, avec des enfants** (0.47.0) : le mot
      qui compte là où on le voit suffit-il, ou faut-il la **marge
      invisible** autour des boîtes (proposée, écartée pour l'instant) ? Si
      oui : la plus proche l'emporte quand deux marges se chevauchent, et le
      calcul va dans le moteur. À juger aussi : le blanc à 90 % au survol,
      le clignotement, le reflet.
- [ ] **Éprouver le « Bravo ! » au doigt** (0.49.0) : la pause avant qu'il
      paraisse (0,45 s), la taille de Grisbie en coin, la longueur du texte
      proposé pour un lecteur de six ans.
- [ ] **Voir l'icône et l'écran de chargement sur le téléphone** (0.48.0) :
      les deux saveurs, sur un Android 12 ou plus et si possible un plus
      ancien. Rien n'a pu être construit ici. Au passage : le manifeste web
      s'appelle encore `grisbie`, en minuscules, avec la description du
      modèle Flutter — à nommer par l'auteur.
- [ ] **Éprouver « Essayer » sur le téléphone** : un lieu, puis l'aventure
      entière, après un enregistrement fait depuis l'ordinateur.

## Plus tard — décidé, pas encore le moment

- [ ] **Un aperçu multi-formats dans l'outil** : la scène dans deux ou trois
      cadres de téléphone (360×640, 390×844, tablette) sur l'ordinateur,
      pour attraper sans téléphone un énoncé trop long ou une zone trop
      petite. Ne remplace pas l'essai au doigt.

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
- [x] **Le CORS du bucket.** Fait, et éprouvé : le contenu se lit désormais
      depuis le dépôt dans Chrome. La marche à suivre est dans `Commandes.md`.
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
- [ ] **Éprouver l'écran de structure** sur le téléphone et dans Chrome :
      changer la nature d'un lieu, rediriger un trajet, supprimer un lieu
      détaché. Rien n'en a été ouvert.

**La navigation visée depuis l'écran du parcours** — discutée, pas encore
arbitrée en détail. Elle absorbe les étapes 4 à 6 du chantier :

- [x] **Éprouver le dépôt d'une image, et son aperçu.** Fait dans Chrome, le
      22 septembre 2026 : l'image choisie part sur le dépôt et s'affiche.
- [x] **Éprouver la même chose sur le téléphone.** Fait le 22 septembre 2026 :
      l'outil tourne sur l'appareil, images comprises. `image_picker` et
      `path_provider` ont donc enfin été exécutés.
- [ ] **Tout rapatrier d'un bloc.** Le chantier tient en une phrase de
      l'auteur : *construire une aventure depuis le téléphone ou l'ordinateur,
      l'enregistrer sur Storage, puis la télécharger pour l'inclure au dépôt.*
      Les deux premiers tiers sont faits ; la descente, non. Aujourd'hui les
      fichiers descendent un par un, aux noms aplatis, à reposer à la main.

      Les deux premiers morceaux sont faits en 0.28.0 :
      - ~~`ContentSink` ne sait écrire que du texte~~ — `writeBytes` existe.
      - ~~Déposer l'image sur le dépôt et savoir l'y relire~~ — elle s'écrit
        dans l'arbre de contenu dès qu'on la choisit.
      - **Tout redescendre d'un coup** — JSON et images — pour le déposer dans
        `assets/content/` du dépôt git. **Plus rien n'est à réécrire au
        passage** depuis 0.28.0 : le dossier téléchargé *est* l'arbre de
        contenu, illustrations comprises.

      Storage reste un **transit entre les appareils de l'auteur** : le jeu
      livré ne le contacte jamais, et l'enfant ne lit que le bundle.

- [ ] **Remplacer le contenu inventé.** Tout ce qui suit « Devant la maison »
      dans l'aventure livrée — la gare, la boutique, le garage, la rue, la
      plage, et leur vocabulaire — a été **inventé par un agent**, pas écrit
      par l'auteur. Ça se garde en attendant, comme étalon des tests sur du
      contenu réel, mais ça n'a aucune valeur pédagogique et ne doit pas se
      retrouver devant un enfant. La règle qui l'interdit est désormais dans
      `CLAUDE.md` §1.
- [ ] **Éprouver l'écran de liste sur le téléphone et dans Chrome** : créer,
      réutiliser, taper des mots, cocher les listes du
      reste, puis enregistrer et vérifier `lexicon/<id>.json` et
      `lists/<id>.json` sur le dépôt. Rien de cela n'a été ouvert.
- [ ] **Nommer un trajet et sa liste depuis l'écran de liste** : le nom du
      trajet (ce que l'enfant lit) ne se modifie pas encore après coup.
- [ ] **Un bouton « Valider »**, à gauche d'« Ajouter », qui valide les listes.
      Reste à définir ce que « valider » arrête exactement — figer une liste
      close, ou seulement signaler qu'on la considère finie.

## Cadre de travail

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
