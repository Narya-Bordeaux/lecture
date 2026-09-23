# Spécification du jeu de découverte de la lecture

**Version de travail 0.9 — 23 septembre 2026**

## Objet du document

Cette spécification rassemble uniquement les choix déjà formulés pour un jeu numérique destiné aux enfants de 6 à 7 ans. Elle sert de base à une conception commune. Les points qui n’ont pas encore été discutés restent explicitement ouverts.

## Vision du jeu

Le jeu propose à l’enfant de lire plusieurs mots puis de les classer dans des familles de sens déjà nommées, par exemple des animaux, des aliments ou des éléments associés à une situation comme l’école ou la cuisine.

Le classement prend place dans un parcours illustré. L’enfant accompagne le chat Grisbie dans ses aventures. Compléter une famille permet d’avancer sur un chemin, de découvrir des lieux liés au vocabulaire rencontré et de faire progresser une petite histoire.

## Public et contexte d’utilisation

- Public principal : enfants de 6 à 7 ans.
- Le jeu doit réunir plusieurs niveaux de lecture dans une même application ou un même jeu web.
- L’enfant peut jouer seul après l’explication des règles.
- Un adulte peut aider à déchiffrer certains mots et discuter du sens des associations.

## Objectifs d’apprentissage

- Déchiffrer des mots simples.
- Reconnaître plus rapidement des mots déjà rencontrés.
- Comprendre le sens des mots.
- Identifier des familles sémantiques et classer les mots qui leur appartiennent.

## Boucle de jeu confirmée

L'enfant accompagne le chat Grisbie dans ses aventures. Le chat va avoir différentes "journées" ou "aventures" pour lesquelles l'enfant devra classer des mots dans des familles afin que le chat puisse avancer dans sa journée.

Une journée pourra proposer différents chemins par exemple: aller à la plage en transport en commun, à pied, en voiture...

L'enfant a les différents mots: train / chaussure / panneau / gare / station essence

Quand une famille est remplie, il peut avancer sur cette histoire. Il aura alors un autre mini jeu pour avancer dans la gare, par exemple avec boutique / toilettes / guichet qui lui permettent de valider la gare et d'avancer sur ce chemin afin d'arriver à la plage.

1. Le chemin montre plusieurs destinations, chacune associée dès le départ à une famille de mots.
2. La mission et le décor rendent compréhensible le lien entre chaque direction et la famille correspondante. L’enfant ne s’engage sur aucune direction à ce stade.
3. L’étape présente plusieurs mots visibles et plusieurs familles désignées par leur nom.
4. L’enfant choisit un mot et le fait glisser vers le nom de la famille correspondante.
5. Toutes les familles acceptent leurs mots. L’enfant classe librement, dans l’ordre qu’il veut.
6. Si le classement est incorrect, le jeu refuse immédiatement le placement et permet un nouvel essai. Aucune aide n’apparaît, voir « Aides à la lecture ».
7. Dès qu’une famille atteint son objectif, **sa destination devient disponible** : elle s’active sur la carte, sans que l’enfant y soit envoyé. Il peut continuer à classer et rendre plusieurs destinations disponibles.
8. L’enfant part quand il le décide, vers la destination disponible de son choix. À ce moment seulement l’étape se termine, les mots restants disparaissent et le chat avance.

### Réserve de mots et renouvellement

Une famille dispose d'une liste plus longue que ce qui est montré. L'étape
propose un nombre fixe de mots — six au départ — et garde les autres en réserve.

**Dès qu'un mot est bien classé, il quitte la grille et un mot de la réserve
vient reprendre sa place**, et seulement la sienne : les autres mots ne bougent
pas, pour que l'enfant ne perde pas des yeux celui qu'il était en train de
déchiffrer. Un mot mal classé ne déclenche aucun renouvellement.

Le tirage est libre : il peut arriver qu'aucun mot d'une famille donnée ne soit
à l'écran. L'enfant classe alors ailleurs, ce qui renouvelle la réserve. Cela
l'oblige à lire tous les mots plutôt qu'à se concentrer sur une seule famille.

**Les listes sont pleines** : une famille ouvre sa destination lorsque tous ses
mots sont classés. C'est ce que l'enfant voit sur la zone (« 3 / 7 »). Les
listes n'ont pas à être de la même taille d'une famille à l'autre — toutes
n'offrent pas le même champ lexical — et le contenu peut, au besoin, demander
moins que la liste entière.

Remplir entièrement une catégorie est en soi une aide : les mots restants ne
peuvent plus lui appartenir, et le choix se réduit pour ceux qui suivent.

> **Conséquence.** Le choix du chemin arrive tard, une fois l'essentiel de
> l'étape classé, et les trois destinations sont alors souvent ouvertes en même
> temps. Le choix est donc complet plutôt que précoce : l'enfant a fait tout le
> travail de lecture, puis décide où aller.

### Familles et champ lexical

Les familles d'une même étape doivent avoir des vocabulaires **disjoints**, et
c'est une contrainte de conception plus forte qu'il n'y paraît. « En bus » et
« En voiture » partagent presque toute la mécanique — moteur, roue, frein,
siège, portière, phare, ceinture — car un bus est une voiture en plus grand.
Seuls tiennent les mots propres à l'usage : le transport collectif d'un côté
(arrêt, ticket, horaire, guichet), la voiture familiale de l'autre (coffre,
garage, radio, clé).

Mieux vaut choisir des familles aux lexiques naturellement séparés. « En vélo »,
par exemple, offrirait guidon, pédale, casque, sonnette, selle, panier — que ni
le bus ni la marche ne revendiquent.

### Étapes imbriquées

Une destination atteinte ouvre à son tour une étape de même nature, avec ses
propres mots et ses propres familles concurrentes. Arriver à la gare ne clôt donc
pas le parcours : il faut y classer de nouveaux mots pour en repartir. La structure
est récursive, un lieu contenant une étape qui mène à d’autres lieux.

## Aides à la lecture

**Le jeu ne propose aucune aide pendant le classement** (décision du
23 septembre 2026). Un mot mal placé est refusé, l’étiquette revient, et
l’enfant réessaie autant qu’il le faut.

Le découpage du mot en syllabes, affiché dès la première erreur, a été
l’aide unique des versions précédentes. Il a été **retiré**, et avec lui la
donnée elle-même : un mot n’est plus que son orthographe, et l’auteur n’a
plus de découpage à saisir.

### Pourquoi pas d’illustration

Une autre aide — montrer une image du mot — avait été prévue puis **écartée**. Le
nombre de familles fait déjà office d’aide : avec trois catégories, les
possibilités se réduisent d’elles-mêmes à mesure qu’elles se remplissent, et
l’enfant qui a oublié le sens d’un mot finit par n’avoir plus qu’un choix.
Ajouter l’image reviendrait à donner la réponse.

> **Conséquence assumée.** La fin d’une étape devient facile : quand deux
> familles sont pleines, les derniers mots se classent sans être lus. C’est un
> soulagement pour un enfant en difficulté, et sans intérêt pour un bon lecteur
> — d’où le nombre de familles comme axe de progression, déjà retenu plus bas.

## Progression et difficulté

La difficulté doit pouvoir varier au sein du même jeu. Les axes de progression déjà retenus sont les suivants :

- la longueur des mots et leur difficulté de déchiffrage ;
- le caractère plus ou moins évident des familles ;
- le nombre de familles et de mots visibles, qui varie selon le niveau. Plus il
  y a de familles, moins leur remplissage progressif aide l’enfant.

### Mots ambigus

Les mots ambigus, qui pourraient raisonnablement appartenir à plusieurs familles proposées dans la même étape, doivent être évités.

## Parcours et univers

- Le fond d’écran représente une scène cohérente avec les thématiques travaillées.
- Le chemin relie un point de départ à un point d’arrivée.
- Le parcours donne accès à des lieux associés à des vocabulaires différents.
- Chaque classement s’inscrit dans une mission qui donne un sens aux mots proposés.
- Un court épisode de l’histoire apparaît après chaque avancée.
- Le parcours propose plusieurs directions ou plusieurs thèmes.
- Les choix de chemin modifient l’histoire.
- Chaque direction affiche dès le départ la destination et la famille qui lui correspondent.
- Depuis la carte, l’enfant peut revenir immédiatement à une bifurcation déjà franchie pour explorer l’autre chemin.
- L’enfant nomme son personnage, mais il n'apparaît jamis dans le jeu, il est interpellé "Charles/Julie aide le chat Grisbie à aller à la plage".

## État de la spécification

| État | Éléments concernés |
|---|---|
| Confirmé | Public, objectifs pédagogiques, support numérique, classement par glisser-déposer, refus immédiat d’une erreur, **aucune aide à la lecture** (découpage syllabique retiré, illustration écartée), listes pleines, réserve et renouvellement sur place, classement libre sans engagement préalable, destination rendue disponible par la complétion de sa famille, départ à l’initiative de l’enfant, disparition des mots restants, étapes imbriquées, retour immédiat aux bifurcations, personnage nommé mais jamais représenté, parcours narratif autour du chat Grisbie, **tri unique** (une liste et son complément, une seule sortie) comme seconde mécanique de classement, personnage rencontré **retiré** (ce qu'il disait relève de la narration). |
| À préciser | Forme de la carte, niveaux détaillés, récompenses, durée d’une session, suivi de la progression et rôle précis de l’adulte. |

## Questions ouvertes pour la prochaine version

- Que voit l’enfant sur le chemin avant et après une étape ?
- Quelle forme générale la carte et ses bifurcations prennent-elles ?
- Comment le niveau de lecture initial est-il choisi ?
- Quels contenus, quantités et aides correspondent à chaque niveau ?
- Comment l’application montre-t-elle les progrès à l’enfant et à l’adulte ?
