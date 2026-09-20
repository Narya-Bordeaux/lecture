# Comment écrire une aventure

Ce document décrit les fichiers de contenu du jeu. Il s'adresse à qui veut
**écrire ou modifier une aventure** — ajouter des mots, un lieu, un personnage —
sans toucher au code. Aucune connaissance de programmation n'est nécessaire.

Tout le contenu vit dans `assets/content/`. Les fichiers sont au format JSON :
du texte structuré par des accolades, des crochets et des guillemets. Les
virgules et les guillemets comptent ; un éditeur de texte qui colore le JSON
(VS Code, Notepad++) signale les oublis immédiatement.

## Les quatre sortes de fichiers

```
assets/content/
  index.json            ← le sommaire : ce qui existe
  lexicon/*.json        ← le vocabulaire, regroupé par domaine
  characters.json       ← les personnages
  adventures/*.json     ← les aventures et leurs lieux
```

Le principe est simple : **un mot n'est défini qu'une fois**, dans le lexique.
Les aventures ne font que le nommer. C'est ce qui évite qu'un même mot se
retrouve découpé `gâ-teau` à un endroit et `gât-eau` à un autre — l'enfant
verrait les deux.

## 1. Le sommaire — `index.json`

Il ne contient aucun contenu de jeu, seulement la liste de ce qui existe.

```json
{
  "lexicons": ["lexicon/transport.json", "lexicon/food.json"],
  "characters": "characters.json",
  "adventures": [
    {
      "id": "grisbie_beach",
      "title": "Grisbie va à la plage",
      "cover": "assets/pictures/Grisbie_plage.jpg",
      "file": "adventures/grisbie_beach.json"
    }
  ]
}
```

| Champ | Obligatoire | Rôle |
|---|---|---|
| `lexicons` | oui | Les fichiers de vocabulaire à charger |
| `characters` | non | Le fichier des personnages |
| `adventures` | oui | Les aventures jouables |
| `id` | oui | Nom interne, sans espace ni accent |
| `title` | oui | Le titre montré au joueur |
| `cover` | non | Image de présentation |
| `file` | oui | Où trouver l'aventure |

**Toute nouvelle aventure ou tout nouveau fichier de vocabulaire doit être
ajouté ici**, sinon le jeu ne le verra pas.

## 2. Le vocabulaire — `lexicon/*.json`

Un fichier par domaine : les transports, la nourriture, la nature… Le découpage
en domaines n'a aucun effet sur le jeu, il sert seulement à s'y retrouver.

```json
{
  "domain": "food",
  "words": [
    { "id": "cake", "text": "gâteau", "syllables": ["gâ", "teau"] },
    { "id": "apple", "text": "pomme", "syllables": ["pomme"] }
  ]
}
```

- `id` — le nom interne du mot, utilisé par les aventures. Sans espace ni
  accent, et **unique dans tout le jeu**.
- `text` — le mot tel que l'enfant le lit, accents compris.
- `syllables` — le découpage, dans l'ordre. Mis bout à bout, il doit
  reconstituer exactement le mot : `["gâ", "teau"]` donne bien `gâteau`.

Le découpage n'est jamais calculé par le jeu. Le français n'a pas de règle de
syllabation assez sûre pour être automatisée, et une syllabe fausse tromperait
l'enfant sur le point même qu'on cherche à travailler. Un mot d'une seule
syllabe s'écrit `["pomme"]`.

## 3. Les personnages — `characters.json`

```json
{
  "characters": [
    { "id": "fisherman", "name": "Le pêcheur" },
    { "id": "shopkeeper", "name": "La marchande de journaux", "portrait": "assets/pictures/marchande.png" }
  ]
}
```

Le personnage ne contient que ce qui ne change pas d'une scène à l'autre : son
nom, son portrait. **Ce qu'il dit appartient au lieu où on le rencontre**, et
s'écrit dans l'aventure. Le même personnage peut ainsi revenir ailleurs avec
d'autres répliques.

## 4. Une aventure — `adventures/*.json`

Une aventure est une « journée » : un ensemble de lieux reliés entre eux.

```json
{
  "id": "grisbie_beach",
  "title": "Grisbie va à la plage",
  "startStageId": "home",
  "stages": [ … ]
}
```

`startStageId` désigne le lieu par lequel on commence.

### La page de garde — `opening`

Une aventure peut s'ouvrir sur un écran d'accueil, montré **une seule fois**
avant le premier lieu : un titre en haut, une illustration en pleine largeur, le
texte dessous.

```json
"opening": {
  "title": "Grisbie part à la plage",
  "image": "assets/pictures/Grisbie_plage.jpg",
  "text": "Ce matin, Grisbie a mis son sac à dos et pris sa carte."
}
```

| Champ | Obligatoire | Rôle |
|---|---|---|
| `title` | non | Le titre affiché. Absent, celui de l'aventure prend sa place |
| `image` | non | L'illustration d'accueil, montrée **entière**, à ses proportions |
| `text` | oui | Ce que l'on raconte avant de partir |

Contrairement aux décors de jeu, cette illustration n'est jamais recadrée et
peut donc être **horizontale** : elle occupe la largeur, sa hauteur suit ses
proportions. C'est le bon endroit pour une vue d'ensemble.

Le champ `opening` est facultatif : sans lui, l'aventure démarre directement sur
son premier lieu.

### Un lieu

```json
{
  "id": "gas_station",
  "location": "La station-service",
  "background": "assets/pictures/station.jpg",
  "narrative": {
    "onArrival": "La voiture a soif ! Grisbie s'arrête faire le plein.",
    "onCompletion": "Le réservoir est plein. En route vers la mer !"
  },
  "visibleWordCount": 6,
  "families": [ … ]
}
```

| Champ | Obligatoire | Rôle |
|---|---|---|
| `id` | oui | Nom interne, cité par les autres lieux comme destination |
| `location` | oui | Le nom du lieu, montré au joueur |
| `background` | non | L'illustration de fond |
| `backgroundColor` | non | La couleur qui comble au-dessus de l'illustration, en `#RRGGBB` |
| `narrative.onArrival` | non | Texte affiché en arrivant, **avant** de jouer |
| `narrative.onCompletion` | non | Texte affiché au moment de repartir |
| `visibleWordCount` | non | Combien de mots sont proposés à la fois (6 par défaut) |
| `character` | non | Le personnage rencontré ici |
| `families` | oui | Les catégories à remplir |

**Il n'y a pas de champ indiquant le type du lieu.** La structure le dit :
un lieu avec un `character` est une rencontre, un lieu sans `families` est une
arrivée qui clôt l'aventure. Rien à déclarer, donc rien qui puisse contredire
le contenu réel.

### Une famille

```json
{
  "id": "fuel",
  "label": "Le plein",
  "words": ["petrol", "oil", "air", "pump"],
  "destination": "coast_road",
  "area": { "left": 0.05, "top": 0.35, "width": 0.3, "height": 0.16 }
}
```

| Champ | Obligatoire | Rôle |
|---|---|---|
| `id` | oui | Nom interne |
| `label` | oui | Le nom de la catégorie, lu par l'enfant |
| `words` | oui | Les identifiants des mots, pris dans le lexique |
| `destination` | non | Le lieu qui s'ouvre quand la famille est complète |
| `area` | non | Où poser la zone sur l'illustration |
| `goal` | non | Combien de mots suffisent (toute la liste par défaut) |

**Une famille sans `destination` ne mène nulle part.** C'est le classeur de
rebut d'une énigme : l'enfant y range ce qui ne répond pas à la question, et le
remplir n'ouvre aucun chemin.

### L'illustration et la bande du haut

L'illustration est affichée **en entier** et **calée en bas**. Elle n'est jamais
recadrée : sur un téléphone allongé — 1080 × 2340, soit 1 : 2,17, contre 1 : 1,5
pour une image en portrait classique — le recadrage ferait sortir un quart de
l'image de chaque côté, **emportant les zones avec lui**.

Il reste donc une bande libre en haut, qu'occupe le bandeau des mots. Donnez-lui
la couleur du haut de votre illustration, avec `backgroundColor` : si c'est du
ciel, la jointure devient invisible. Pour la trouver, ouvrez l'image dans
n'importe quel éditeur et prélevez la couleur d'un pixel du bord supérieur.

Cela veut dire que **le bas de l'illustration est la partie sûre** : c'est elle
qui reste visible quel que soit l'appareil. Placez-y ce qui compte — le
personnage, le chemin, les éléments que désignent les zones.

### Où poser une zone — `area`

Les quatre nombres sont des **fractions de l'illustration**, entre 0 et 1, et
non des pixels. `left: 0.05` signifie « à 5 % du bord gauche ». La zone reste
ainsi posée sur le bus quelle que soit la taille de l'écran.

```
left ──►┌──────────┐
top     │          │ height
  │     └──────────┘
  ▼        width
```

Pour trouver les valeurs : ouvrir l'image, repérer l'élément, et diviser sa
position par la largeur (ou la hauteur) totale. Un élément commençant à 300
pixels sur une image large de 1024 donne `left: 0.29`.

Deux zones ne doivent pas se chevaucher, sinon le dépôt devient ambigu.

## 5. Une rencontre

Une rencontre est un lieu ordinaire, avec un personnage et **deux familles dont
une ne mène nulle part** :

```json
{
  "id": "harbour",
  "location": "Le port",
  "character": {
    "id": "fisherman",
    "line": "Aide-moi ! Trouve tout ce qui parle de la mer."
  },
  "families": [
    { "id": "sea", "label": "Pour le pêcheur",
      "words": ["wave", "sand", "shell", "boat", "fish", "seaweed", "crab"],
      "destination": "beach", "area": { … } },
    { "id": "keep", "label": "Garde-le",
      "words": ["notebook", "hammer", "hen", "handlebar", "chalk", "fir", "sweet"],
      "area": { … } }
  ]
}
```

La réplique du personnage remplace la consigne habituelle au-dessus des mots :
elle dit ce qu'il faut faire, et mieux qu'une phrase générique.

**Les leurres sont écrits à la main, jamais tirés au hasard.** Le tirage
automatique dans les autres listes exposerait à sortir un mot qui appartient
vraiment au thème — l'enfant le classerait correctement et le jeu le
refuserait. Punir une bonne réponse est la pire erreur possible ici. Écrits une
fois, les leurres sont vérifiés une fois.

Comptez **autant de leurres que de mots du thème**. Un rebut beaucoup plus gros
noierait le thème, les mots proposés étant tirés de l'ensemble.

## 6. Les règles que le jeu vérifie tout seul

Au chargement, le contenu est contrôlé. En cas de problème, le jeu refuse de
démarrer et affiche la liste précise des fautes — mieux vaut un message clair
qu'une partie qui se bloque sans raison.

Sont détectés :

- un mot cité mais absent du lexique, **nommé** ;
- un mot défini deux fois, dans le même fichier ou entre deux fichiers ;
- un personnage cité mais absent de `characters.json` ;
- une destination qui désigne un lieu inexistant ;
- un lieu qu'aucun chemin ne permet d'atteindre ;
- une famille vide ;
- **un mot présent dans deux familles du même lieu** — c'est le « mot ambigu »
  que la conception proscrit ;
- **un mot qui apparaît dans le nom de sa famille** (« bus » dans « En bus ») :
  l'enfant le classerait en comparant les lettres, sans comprendre le sens ;
- un lieu dont aucune famille ne mène ailleurs, donc sans issue ;
- une zone qui déborde de l'illustration, ou qui en chevauche une autre.

## 7. Les pièges de contenu, qui eux ne sont pas détectables

Le jeu ne peut pas juger du sens. Ces points relèvent de la relecture humaine.

**Des familles au vocabulaire disjoint.** C'est la contrainte la plus coûteuse.
« En bus » et « En voiture » partagent toute la mécanique — moteur, roue, frein,
siège, phare, ceinture — puisqu'un bus est une voiture en plus grand. Seuls
tiennent les mots propres à l'usage : le transport collectif d'un côté (arrêt,
ticket, guichet), la voiture familiale de l'autre (coffre, garage, radio, clé).
Mieux vaut choisir des catégories franches — les fruits et les légumes, les
animaux et les arbres — que deux parties d'un même lieu.

**Les mots à double sens.** `tomate` n'a pas sa place entre « les fruits » et
« les légumes ». `panier` irait au vélo comme au goûter. Ce sont les mots qu'on
retire six mois plus tard, après avoir vu un enfant hésiter.

**La longueur des mots.** Le public a 6-7 ans. `correspondance` et `terminus`
ne se déchiffrent pas comme `pas` ou `clé`. La longueur est d'ailleurs un des
axes prévus pour faire varier la difficulté.

## 8. Ajouter un lieu : la marche à suivre

1. Écrire les mots manquants dans le fichier de lexique du bon domaine.
2. Ajouter le lieu dans `stages`, avec son `id`, son `location` et ses
   `families`.
3. Faire pointer vers lui la `destination` d'une famille d'un lieu existant —
   sinon il restera inatteignable, et le jeu le signalera.
4. Lancer `flutter test` : le contenu est vérifié automatiquement.
