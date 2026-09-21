# Comment écrire une aventure

Ce document décrit les fichiers de contenu du jeu. Il s'adresse à qui veut
**écrire ou modifier une aventure** — ajouter des mots, un lieu, un personnage —
sans toucher au code. Aucune connaissance de programmation n'est nécessaire.

Tout le contenu vit dans `assets/content/`. Les fichiers sont au format JSON :
du texte structuré par des accolades, des crochets et des guillemets. Les
virgules et les guillemets comptent ; un éditeur de texte qui colore le JSON
(VS Code, Notepad++) signale les oublis immédiatement.

## Les cinq sortes de fichiers

```
assets/content/
  index.json            ← le sommaire : ce qui existe
  lexicon/*.json        ← le vocabulaire, regroupé par domaine
  lists/*.json          ← les listes de mots, par thème
  characters.json       ← les personnages
  adventures/*.json     ← les aventures et leurs lieux
```

Le principe est simple : **un mot n'est défini qu'une fois**, dans le lexique.
Tout le reste ne fait que le citer. C'est ce qui évite qu'un même mot se
retrouve découpé `gâ-teau` à un endroit et `gât-eau` à un autre — l'enfant
verrait les deux.

Trois fichiers, trois questions distinctes, et c'est ce qui justifie qu'ils
soient séparés :

| Fichier | Répond à |
|---|---|
| `lexicon/*.json` | comment le mot s'écrit et se découpe |
| `lists/*.json` | de quoi le mot parle |
| `adventures/*.json` | où cette liste se pose, sous quel nom, vers quelle sortie |

Tout s'écrit en français, y compris les noms internes. Le jeu n'a pas vocation
à être traduit : **un mot est désigné par son orthographe**, pas par une clé
technique. On écrit `"gâteau"` dans une aventure, et c'est tout.

## 1. Le sommaire — `index.json`

Il ne contient aucun contenu de jeu, seulement la liste de ce qui existe.

```json
{
  "lexicons": ["lexicon/transport.json", "lexicon/nourriture.json"],
  "lists": ["lists/transport.json", "lists/quotidien.json"],
  "characters": "characters.json",
  "adventures": [
    {
      "id": "grisbie_plage",
      "title": "Grisbie va à la plage",
      "cover": "assets/pictures/Grisbie_plage.jpg",
      "file": "adventures/grisbie_plage.json"
    }
  ]
}
```

| Champ | Obligatoire | Rôle |
|---|---|---|
| `lexicons` | oui | Les fichiers de vocabulaire à charger |
| `lists` | non | Les fichiers de listes de mots à charger |
| `characters` | non | Le fichier des personnages |
| `adventures` | oui | Les aventures jouables |
| `id` | oui | Nom interne, sans espace ni accent |
| `title` | oui | Le titre montré au joueur |
| `cover` | non | Image de présentation |
| `file` | oui | Où trouver l'aventure |

**Tout nouveau fichier — aventure, vocabulaire, listes — doit être ajouté
ici**, sinon le jeu ne le verra pas. Et s'il s'agit d'un nouveau *répertoire*,
il faut aussi le déclarer dans `pubspec.yaml` : Flutter n'embarque pas les
sous-dossiers qu'on ne lui nomme pas.

## 2. Le vocabulaire — `lexicon/*.json`

Un fichier par domaine : les transports, la nourriture, la nature… Le découpage
en domaines n'a aucun effet sur le jeu, il sert seulement à s'y retrouver.

```json
{
  "domain": "nourriture",
  "words": [
    { "text": "gâteau", "syllables": ["gâ", "teau"] },
    { "text": "pomme", "syllables": ["pomme"] }
  ]
}
```

- `text` — le mot tel que l'enfant le lit, accents compris. **C'est lui qui
  identifie le mot** : c'est ce qu'on écrira dans les aventures, et il doit
  être unique dans tout le jeu.
- `syllables` — le découpage, dans l'ordre. Un mot d'une seule syllabe s'écrit
  `["pomme"]`.

**Le découpage suit les sons, pas les lettres.** C'est une règle pédagogique et
non la syllabation graphique académique : on écrit `["a", "rê"]` pour « arrêt »,
`["é", "ssence"]` pour « essence ». Le découpage n'a donc pas à reconstituer
l'orthographe du mot, et rien ne le vérifie — c'est votre jugement qui fait foi.
L'enfant voit de toute façon les deux : le mot écrit sur l'étiquette, et son
découpage juste en dessous.

Le découpage n'est jamais calculé par le jeu. Le français n'a pas de règle de
syllabation assez sûre pour être automatisée, et une coupe fausse tromperait
l'enfant sur le point même qu'on cherche à travailler.

> **Deux mots de même orthographe sont impossibles.** « La marche » et « il
> marche » ne peuvent pas coexister : à l'écran, l'enfant ne verrait qu'une
> seule étiquette, sans moyen de les distinguer. Le chargement refuse le
> doublon en nommant le mot.

## 3. Les listes de mots — `lists/*.json`

Une liste rassemble les mots d'un **thème** : le bus, la nourriture, les objets
d'une boutique. Un fichier peut en contenir plusieurs.

```json
{
  "domain": "transport",
  "lists": [
    {
      "id": "bus",
      "name": "Le bus",
      "words": ["arrêt", "ticket", "horaire", "abri", "ligne", "terminus"]
    }
  ]
}
```

- `id` — le nom interne, cité par les familles d'une aventure.
- `name` — un nom de travail, **pour vous**. L'enfant ne le voit jamais : ce
  qu'il lit, c'est le `label` de la famille.
- `words` — les mots, écrits tels qu'ils figurent dans le lexique.

Deux propriétés font tout l'intérêt de cet objet.

**Une liste sert à plusieurs endroits.** Le même thème peut être rejoué dans un
autre lieu, dans une autre aventure : on cite son `id`, on ne recopie rien.
C'est pourquoi les listes ne vivent pas *dans* les aventures.

**Une liste est plus grande que la partie.** À l'entrée d'un lieu, le jeu n'en
tire que quelques mots (`drawCount`, §5). Écrire vingt mots pour une partie qui
en montre sept n'est pas du gâchis : c'est ce qui fait que **rejouer la même
journée ne redonne pas les mêmes mots**.

> **Un même mot peut appartenir à plusieurs listes**, et c'est justement ce que
> le lexique interdit. « gâteau » est à la fois de la nourriture et de ce qu'on
> achète à la gare. Il n'est défini qu'une fois, et cité deux fois.
>
> En revanche, un mot **répété dans la même liste** est refusé : il compterait
> deux fois au tirage et pourrait s'afficher en double.

## 4. Les personnages — `characters.json`

```json
{
  "characters": [
    { "id": "pecheur", "name": "Le pêcheur" },
    { "id": "marchande", "name": "La marchande de journaux", "portrait": "assets/pictures/marchande.png" }
  ]
}
```

Le personnage ne contient que ce qui ne change pas d'une scène à l'autre : son
nom, son portrait. **Ce qu'il dit appartient au lieu où on le rencontre**, et
s'écrit dans l'aventure. Le même personnage peut ainsi revenir ailleurs avec
d'autres répliques.

## 5. Une aventure — `adventures/*.json`

Une aventure est une « journée » : un ensemble de lieux reliés entre eux.

```json
{
  "id": "grisbie_plage",
  "title": "Grisbie va à la plage",
  "startStageId": "maison",
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

> **Ne redites pas la page de garde dans le premier lieu.** Si l'ouverture
> annonce déjà « Grisbie veut aller à la plage », laissez le `onArrival` du lieu
> de départ vide. Sinon l'enfant enchaîne deux écrans de texte avant de jouer,
> dont le second n'apprend rien — il attend, simplement.

### Un lieu

```json
{
  "id": "station_service",
  "location": "La station-service",
  "background": "assets/pictures/station.jpg",
  "narrative": {
    "onArrival": "La voiture a soif ! Grisbie s'arrête faire le plein."
  },
  "visibleWordCount": 6,
  "drawCount": 7,
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
| `visibleWordCount` | non | Combien de mots sont proposés **à la fois** sur le bandeau (6 par défaut) |
| `drawCount` | non | Combien de mots **chaque famille** tire de sa liste (toute la liste par défaut) |
| `character` | non | Le personnage rencontré ici |
| `families` | oui | Les catégories à remplir |

**Un lieu raconte son arrivée, jamais son départ.** L'enfant y entre, lit ce qui
donne son sens à ce qui va lui être demandé, puis classe ses mots. Quand il
repart en cliquant un trajet, c'est le **lieu suivant** qui raconte, avec son
propre `onArrival`. La narration appartient à celui qui accueille.

Ne pas confondre les deux nombres. `drawCount` dit combien de mots entrent en
jeu **par famille** — trois familles à 7 font 21 mots pour le lieu.
`visibleWordCount` dit combien d'étiquettes tiennent **à l'écran** en même
temps ; les autres attendent en réserve, et un mot bien classé libère sa place.

**Il n'y a pas de champ indiquant le type du lieu.** La structure le dit : un
lieu dont une famille n'a pas de `destination` fait un **tri unique** (§6), un
lieu sans `families` est une fin. Rien à déclarer, donc rien qui puisse
contredire le contenu réel — à une exception près, `ending`, expliquée au §7.

Le `character` ne dit rien du type du lieu : c'est un **ornement**, qu'on pose
où l'on veut. Un tri unique s'en passe, un lieu ordinaire peut en porter un.

### Une famille

```json
{
  "id": "le_plein",
  "label": "Le plein",
  "list": "station_service",
  "drawCount": 7,
  "destination": "route_de_la_cote",
  "area": { "left": 0.05, "top": 0.35, "width": 0.3, "height": 0.16 }
}
```

| Champ | Obligatoire | Rôle |
|---|---|---|
| `id` | oui | Nom interne |
| `label` | oui | Le nom de la catégorie, lu par l'enfant |
| `list` | oui | L'`id` de la liste (§3) où la famille puise ses mots |
| `drawCount` | non | Combien de mots tirer ici, si autre chose que le `drawCount` du lieu |
| `destination` | non | Le lieu qui s'ouvre quand la famille est complète |
| `area` | non | Où poser la zone sur l'illustration |
| `goal` | non | Combien de mots suffisent (toute la liste par défaut) |

**Une famille ne porte pas ses mots, elle cite une liste.** La liste est un
thème réutilisable ; la famille dit où ce thème se pose *ici* — sous quel nom
l'enfant le lit, vers quelle sortie il mène, sur quelle partie de l'image on
dépose. Deux lieux peuvent citer la même liste sans se gêner.

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

**N'écrivez pas ces nombres à la main : l'outil de calage les produit.** Lancez
`lib/main_author.dart` au lieu de `lib/main.dart` — sous Android Studio, clic
droit sur le fichier puis « Run 'main_author.dart' ». Choisissez le lieu, posez
les cadres au doigt sur l'illustration réelle, et appuyez sur « Copier » : le
JSON des quatre fractions part dans le presse-papiers, prêt à coller.

L'outil affiche l'étape telle qu'elle sera jouée — décor, bandeau des mots,
cadres et intitulés. C'est ce qui permet de voir le piège que le calcul ne
montre pas : **une zone posée trop haut passe sous le bandeau des mots**, et le
doigt de l'enfant y est intercepté avant d'atteindre la cible, sans aucun
message. Si un cadre disparaît derrière le bandeau dans l'outil, il faut le
descendre.

La hauteur perdue en haut dépend du format de l'appareil, et pas dans le sens
qu'on croit — la contrainte est la plus forte sur les écrans **les moins**
allongés, où l'illustration occupe toute la hauteur :

| Appareil | Bande inutilisable en haut de l'image |
|---|---|
| Tablette 768 × 1024 | 14,3 % |
| Petit téléphone 360 × 640 | 11,0 % |
| Téléphone courant 390 × 844 | aucune |
| Téléphone allongé 412 × 915 | aucune |

Règle simple pour une illustration en 2:3 : **ne descendez pas `top` en dessous
de 0,15.**

L'outil empêche par construction une zone de sortir de l'illustration ou de
devenir plus petite que 48 points — la cible qu'un doigt d'enfant peut viser —
et signale en rouge deux zones qui se chevauchent, le dépôt y étant ambigu.

Au besoin, les valeurs restent calculables à la main : diviser la position d'un
élément par la largeur (ou la hauteur) totale de l'image. Un élément commençant
à 300 pixels sur une image large de 1024 donne `left: 0.29`.

## 6. Un tri unique

**C'est une autre mécanique de lecture, pas un ornement narratif.** Au lieu de
trier entre plusieurs familles homogènes, l'enfant trie entre **une liste et son
complément** : ce qui est du thème, et tout le reste.

La différence porte sur ce que l'enfant fait. Dans un tri à trois familles, il
compare les mots entre eux, et le choix se réduit à mesure que les listes se
remplissent — remplir une catégorie est en soi une aide. Dans un tri unique, il
n'y a rien à comparer : chaque mot se juge seul contre un seul critère, il en
est ou il n'en est pas. C'est plus abstrait, et plus difficile.

Un tri unique est un lieu portant **deux familles dont une ne mène nulle part** —
et **une seule sortie**, celle que le thème ouvre. Rien ne se déclare : la
famille sans destination suffit à le dire.

Le personnage ci-dessous est facultatif. Il pose la question qui énonce le
critère, ce qui aide, mais un tri unique s'en passe très bien, et un lieu
ordinaire peut en porter un.

```json
{
  "id": "port",
  "location": "Le port",
  "character": {
    "id": "pecheur",
    "line": "Aide-moi ! Trouve tout ce qui parle de la mer."
  },
  "families": [
    { "id": "pour_le_pecheur", "label": "Pour le pêcheur",
      "list": "la_mer", "drawCount": 7,
      "destination": "plage", "area": { … } },
    { "id": "a_garder", "label": "Garde-le",
      "list": "objets_divers", "drawCount": 7,
      "area": { … } }
  ]
}
```

La réplique du personnage remplace la consigne habituelle au-dessus des mots :
elle dit ce qu'il faut faire, et mieux qu'une phrase générique.

**Les mots du reste s'écrivent, ils ne se devinent pas.** Il n'existe pas de
« tout le vocabulaire du jeu moins le thème » : un ramassage automatique
sortirait un mot appartenant vraiment au thème, l'enfant le classerait
correctement et le jeu le refuserait. Punir une bonne réponse est la pire erreur
possible ici.

C'est précisément là que la liste réutilisable rapporte le plus. Une seule liste
d'objets hétéroclites, écrite une fois et relue une fois, sert **tous** les tris
uniques du jeu : chacun en retranche automatiquement son propre thème (§8, « Les
mots communs »). Le danger que cette règle voulait éviter est exactement celui
que le retrait supprime — à condition que le mot soit écrit dans les deux
listes, et lui seul.

Comptez **autant de mots tirés du reste que du thème** — deux `drawCount`
égaux. Une moitié beaucoup plus fournie noierait l'autre.

**Une seule sortie**, et le jeu le vérifie : un lieu qui aurait sa liste du
reste et deux destinations ne serait plus un tri unique, mais un tri ordinaire
affublé d'une liste de rebut. Le chargement le refuse.

## 7. Les règles que le jeu vérifie tout seul

Au chargement, le contenu est contrôlé. En cas de problème, le jeu refuse de
démarrer et affiche la liste précise des fautes — mieux vaut un message clair
qu'une partie qui se bloque sans raison.

Sont détectés :

- un mot cité mais absent du lexique, **nommé** ;
- **deux entrées de même orthographe**, dans le même fichier ou entre deux
  fichiers : le mot étant sa propre clé, rien ne dirait lequel des deux
  découpages s'applique ;
- un personnage cité mais absent de `characters.json` ;
- une destination qui désigne un lieu inexistant ;
- un lieu qu'aucun chemin ne permet d'atteindre ;
- une famille vide ;
- une **liste citée mais introuvable**, ou un mot **répété dans une liste** ;
- une famille dont la liste, **une fois les mots communs retirés**, ne contient
  plus assez de mots pour le `drawCount` demandé ;
- une famille dont la liste est **entièrement absorbée** par ses voisines : les
  deux listes disent alors la même chose ;
- **un mot qui apparaît dans le nom de sa famille** (« bus » dans « En bus ») :
  l'enfant le classerait en comparant les lettres, sans comprendre le sens ;
- un lieu dont aucune famille ne mène ailleurs, donc sans issue ;
- une zone qui déborde de l'illustration, ou qui en chevauche une autre ;
- un lieu qui **se déclare fin tout en portant des familles**, ou qui n'a aucune
  famille **sans se déclarer fin** ;
- un **tri unique qui aurait plusieurs sorties** — une liste du reste va avec un
  seul chemin.

### `ending` — une fin se déclare

Un lieu qui clôt le parcours porte `"ending": true` et n'a aucune famille.

C'est une information en double avec la structure, ce que le format évite
partout ailleurs. Elle est acceptée ici parce que l'absence de famille ne
suffisait pas : un lieu qu'on vient de créer et qu'on n'a pas encore écrit n'en
a pas non plus, et passait donc pour une fin sans que rien ne le signale.

La contrepartie est que les deux ne peuvent pas se contredire : une fin qui
porte des familles est refusée, et un lieu sans famille qui ne se déclare pas
fin est signalé comme inachevé.

### Faux, ou seulement incomplet

Le jeu refuse tout : une aventure qui présente la moindre de ces anomalies est
injouable, et rien ne sert de la lancer. Mais chaque anomalie porte aussi sa
nature, pour l'outil d'auteur, qui doit pouvoir ouvrir un travail en cours.

**Faux** — ne s'arrangera pas en continuant d'écrire : un mot présent dans le
nom de sa famille, une liste entièrement absorbée par ses voisines, une zone qui
déborde ou qui en chevauche une autre, un lieu de départ introuvable.

**Incomplet** — état normal d'un lieu qu'on vient de créer : une famille sans
mots, une liste à qui il manque quelques mots pour son tirage, un mot sans
découpage, un lieu dont aucune famille ne mène encore ailleurs, un lieu que rien
ne relie, une destination annoncée avant que son lieu existe.

Cette dernière mérite un mot. Écrire « le bus va au marché » puis créer le marché
est une façon normale d'avancer. Une promesse pas encore tenue et une faute de
frappe sont de toute façon **indiscernables** : les traiter en faute
interdirait d'écrire le parcours dans l'ordre où il se raconte. C'est donc à la
relecture, et au refus du jeu, qu'une destination fantôme se voit.

## 8. Les pièges de contenu, qui eux ne sont pas détectables

Le jeu ne peut pas juger du sens. Ces points relèvent de la relecture humaine.

**Le découpage syllabique.** Il suit les sons, il peut donc légitimement
s'écarter de l'orthographe : aucun contrôle automatique n'est possible sans
interdire du même coup les découpages que vous voulez. Seule son absence est
signalée. C'est le point à relire le plus attentivement, puisque c'est la seule
aide du jeu.

**Des familles au vocabulaire disjoint.** C'est la contrainte la plus coûteuse,
et le jeu n'en prend en charge que la moitié facile — voir « Les mots communs »
ci-dessous. « En bus » et « En voiture » partagent toute la mécanique — moteur,
roue, frein, siège, phare, ceinture — puisqu'un bus est une voiture en plus
grand. Seuls tiennent les mots propres à l'usage : le transport collectif d'un
côté (arrêt, ticket, guichet), la voiture familiale de l'autre (coffre, garage,
radio, clé). Mieux vaut choisir des catégories franches — les fruits et les
légumes, les animaux et les arbres — que deux parties d'un même lieu.

**Les mots à double sens.** `tomate` n'a pas sa place entre « les fruits » et
« les légumes ». `panier` irait au vélo comme au goûter. Ce sont les mots qu'on
retire six mois plus tard, après avoir vu un enfant hésiter.

Attention : ce piège-là subsiste entier. Le retrait automatique ne voit que
l'orthographe. `klaxon` écrit dans la seule liste « voiture », alors qu'un bus
en a un aussi, sera bel et bien proposé — et le jeu refusera l'enfant qui le
classe au bus. Le jugement de sens reste le vôtre.

**La longueur des mots.** Le public a 6-7 ans. `correspondance` et `terminus`
ne se déchiffrent pas comme `pas` ou `clé`. La longueur est d'ailleurs un des
axes prévus pour faire varier la difficulté.

### Les mots communs sont retirés, pas interdits

Un mot présent dans **deux listes d'un même lieu** ne provoque plus de faute :
il est **retiré des deux** avant le tirage, et ne peut donc pas arriver à
l'écran. La règle n'a pas disparu, elle a changé de main — la machine l'applique
au lieu de vous.

Écrire `moteur` dans « le bus » **et** dans « la voiture » devient donc la façon
de dire : *ce mot est ambigu ici*. Ailleurs, sans la liste voisine, il jouera
normalement. C'est ce qui permet à une liste de servir à plusieurs lieux sans
être taillée pour chacun.

Ce que le jeu signale, c'est le **manque** que l'exclusion laisse : s'il ne
reste plus assez de mots pour le `drawCount` demandé, c'est *incomplet* — il
faut en écrire d'autres ; si la liste se vide entièrement, c'est *faux* — les
deux listes disent la même chose.

Comme l'exclusion se calcule **lieu par lieu**, « assez de mots » n'est jamais
une propriété de la liste seule : la même liste tient dans un lieu et manque
dans un autre, selon les listes qui la côtoient.

## 9. Ajouter un lieu : la marche à suivre

1. Écrire les mots manquants dans le fichier de lexique du bon domaine.
2. Les rassembler en une liste dans `lists/`, ou citer une liste existante.
3. Ajouter le lieu dans `stages`, avec son `id`, son `location` et ses
   `families`, chacune citant sa liste.
4. Faire pointer vers lui la `destination` d'une famille d'un lieu existant —
   sinon il restera inatteignable, et le jeu le signalera.
5. Lancer `flutter test` : le contenu est vérifié automatiquement.
