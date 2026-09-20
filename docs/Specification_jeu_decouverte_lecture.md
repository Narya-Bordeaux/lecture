# Spécification du jeu de découverte de la lecture

**Version de travail 0.7 — 20 septembre 2026**

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
6. Si le classement est incorrect, le jeu refuse immédiatement le placement et permet un nouvel essai. Les aides se débloquent sur le mot concerné, voir « Aides à la lecture ».
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

Une famille ouvre sa destination au bout d'un **objectif** plus court que sa
liste. C'est ce nombre que l'enfant voit sur la zone (« 3 / 4 »), et il se règle
famille par famille dans le contenu. Les listes n'ont pas à être de la même
taille : toutes les familles n'offrent pas le même champ lexical.

> **À surveiller.** Plus l'objectif est haut, moins le choix du chemin est un
> vrai choix : avec un tirage libre, l'enfant aura classé la plus grande partie
> de l'étape avant qu'une famille n'atteigne son but, et la question « par où
> partir ? » arrivera trop tard pour se poser. L'objectif est à 4 sur des
> listes de 7.

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

Deux aides peuvent être demandées pendant le classement. Leur disponibilité exacte selon les niveaux reste à définir.

- Afficher le découpage du mot en syllabes.
- Afficher une illustration correspondant au mot.

Les aides se débloquent aussi automatiquement, en fonction du nombre d’erreurs
commises **sur un même mot** :

| Erreurs sur le mot | Aide proposée |
|---|---|
| 1 | Découpage en syllabes |
| 5 | Illustration |

L’écart entre les deux seuils est délibéré. Le découpage arrive tôt, car il aide à
déchiffrer sans livrer le sens : l’enfant garde tout le travail de compréhension.
L’illustration, qui donne le sens et donc presque la réponse, n’arrive qu’après un
effort prolongé.

Une aide débloquée sur un mot le reste jusqu’à la fin de l’étape.

## Progression et difficulté

La difficulté doit pouvoir varier au sein du même jeu. Les axes de progression déjà retenus sont les suivants :

- la longueur des mots et leur difficulté de déchiffrage ;
- la présence ou l’absence d’illustrations ;
- le caractère plus ou moins évident des familles ;
- le nombre de familles et de mots visibles, qui varie selon le niveau.

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
| Confirmé | Public, objectifs pédagogiques, support numérique, classement par glisser-déposer, refus immédiat d’une erreur, seuils des aides automatiques (1 et 5 erreurs), classement libre sans engagement préalable, destination rendue disponible par la complétion de sa famille, départ à l’initiative de l’enfant, disparition des mots restants, étapes imbriquées, retour immédiat aux bifurcations, personnage nommé mais jamais représenté, parcours narratif autour du chat Grisbie. |
| À préciser | Forme de la carte, niveaux détaillés, récompenses, durée d’une session, suivi de la progression et rôle précis de l’adulte. |

## Questions ouvertes pour la prochaine version

- Que voit l’enfant sur le chemin avant et après une étape ?
- Quelle forme générale la carte et ses bifurcations prennent-elles ?
- Comment le niveau de lecture initial est-il choisi ?
- Quels contenus, quantités et aides correspondent à chaque niveau ?
- Comment l’application montre-t-elle les progrès à l’enfant et à l’adulte ?
