# Spécification du jeu de découverte de la lecture

**Version de travail 0.4 — 20 septembre 2026**

## Objet du document

Cette spécification rassemble uniquement les choix déjà formulés pour un jeu numérique destiné aux enfants de 6 à 7 ans. Elle sert de base à une conception commune. Les points qui n’ont pas encore été discutés restent explicitement ouverts.

## Vision du jeu

Le jeu propose à l’enfant de lire plusieurs mots puis de les classer dans des familles de sens déjà nommées, par exemple des animaux, des aliments ou des éléments associés à une situation comme l’école ou la cuisine.

Le classement prend place dans un parcours illustré. L’enfant choisit l’apparence de son personnage parmi plusieurs possibilités. Compléter une famille permet d’avancer sur un chemin, de découvrir des lieux liés au vocabulaire rencontré et de faire progresser une petite histoire.

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

1. Le chemin montre plusieurs destinations, chacune associée dès le départ à une famille de mots.
2. L’enfant choisit une direction. La mission et le décor rendent compréhensible le lien entre cette direction et la famille correspondante.
3. L’étape présente plusieurs mots visibles et plusieurs familles désignées par leur nom.
4. L’enfant choisit un mot et le fait glisser vers le nom de la famille correspondante.
5. Toutes les familles acceptent leurs mots, mais compléter une famille qui ne correspond pas à la direction choisie ne fait pas avancer.
6. Si le classement est incorrect, le jeu refuse immédiatement le placement et permet un nouvel essai. Après plusieurs erreurs sur le même mot, il propose automatiquement le découpage syllabique puis l’illustration.
7. Dès que la famille liée à la direction choisie est entièrement complétée, l’étape se termine, les mots restants disparaissent et l’enfant avance.

## Aides à la lecture

Deux aides peuvent être demandées pendant le classement. Leur disponibilité exacte selon les niveaux reste à définir.

- Afficher une illustration correspondant au mot.
- Afficher le découpage du mot en syllabes.

Après plusieurs erreurs sur le même mot, ces deux aides sont également proposées automatiquement. Le nombre d’erreurs requis et l’ordre d’apparition des aides restent à définir.

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
- L’enfant choisit son personnage parmi plusieurs apparences, sans différence de règles, de mission ou d’histoire.

## État de la spécification

| État | Éléments concernés |
|---|---|
| Confirmé | Public, objectifs pédagogiques, support numérique, classement par glisser-déposer, refus immédiat d’une erreur, aides automatiques après des erreurs répétées, choix préalable d’une destination, autres familles classables sans faire avancer, fin de l’étape lorsque la famille associée est complète, disparition des mots restants, retour immédiat aux bifurcations, personnages purement visuels et parcours narratif. |
| À préciser | Déclenchement et ordre des aides, forme de la carte, contenu d’une étape, niveaux détaillés, récompenses, durée d’une session, suivi de la progression et rôle précis de l’adulte. |

## Questions ouvertes pour la prochaine version

- Que voit l’enfant sur le chemin avant et après une étape ?
- Après combien d’erreurs les aides automatiques apparaissent-elles, et dans quel ordre ?
- Quelle forme générale la carte et ses bifurcations prennent-elles ?
- Comment le niveau de lecture initial est-il choisi ?
- Quels contenus, quantités et aides correspondent à chaque niveau ?
- Comment l’application montre-t-elle les progrès à l’enfant et à l’adulte ?
