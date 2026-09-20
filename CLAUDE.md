# CLAUDE.md — Jeu de découverte de la lecture

> Ce document ne décrit que ce qui existe réellement dans le dépôt.
> Une section n'est ajoutée que le jour où son objet est créé. Ne jamais y
> décrire une intention : les intentions vont dans `docs/TODO.md`.

## 1. Projet

Jeu numérique de découverte de la lecture pour enfants de 6 à 7 ans. L'enfant lit
des mots et les classe dans des familles de sens, au fil d'un parcours illustré.

Le cadrage fonctionnel fait foi : `docs/Specification_jeu_decouverte_lecture.md`.
Ne pas inventer de règle de jeu absente de la spécification — les points non tranchés
y sont listés explicitement comme ouverts.

**Version actuelle : 0.1.0+1** — projet en phase de conception, le code applicatif
n'est pas encore écrit (`lib/main.dart` est encore le squelette généré par Flutter).

**Plateformes visées** : Web, Android, Windows. iOS et macOS ne sont pas visés.

**Pas de serveur** : aucune donnée ne quitte l'appareil. La progression est stockée
localement. Le public étant mineur, toute proposition d'ajout d'un backend, d'un
compte ou d'une télémétrie doit être posée à l'utilisateur, jamais introduite d'office.

## 2. Environnement

- `flutter` / `dart` : **absents de cet environnement cloud**. L'analyse statique,
  les tests et les builds ne peuvent pas y être lancés. Ne pas prétendre avoir
  vérifié du code Dart ici : annoncer explicitement ce qui n'a pas pu être exécuté.
- `node` : disponible (v22).
- Builds Android, Web et Windows : sur le poste de l'utilisateur uniquement.

Commandes à lancer localement après toute modification de code :

```bash
flutter analyze
flutter test
```

## 3. Lire en premier

`docs/current.md` — état courant, version, travail en cours. À lire explicitement
au début de chaque session (aucun hook ne l'injecte pour l'instant).
- Même sujet que la session précédente → continuer. Sujet différent → réinitialiser.
- **Si le contexte a été compacté (session longue) : relire ce fichier.**
- **Mettre à jour en fin de session** : version, ce qui vient d'être fait, chantier
  ouvert ou fermé.

`docs/versions.md` — historique des versions **et procédure de versioning
obligatoire**. La lire avant tout changement de version. Toute session livrant une
fonctionnalité ou une correction donne lieu à un incrément de version.

`docs/TODO.md` — backlog, liste unique et courte de ce qui reste à faire.

## 4. Séparation moteur / interface

C'est la règle structurante du projet. Le moteur de jeu doit pouvoir tourner, et
surtout être testé, **sans Flutter** : même logique réutilisable dans un autre
contexte, et traitement des données homogène.

| Dossier | Contenu | Peut importer Flutter |
|---|---|---|
| `lib/domain/` | Modèles métier et règles pures : mot, famille, étape, niveau, parcours | **Non** |
| `lib/application/` | Moteur de jeu et état : sélection des mots, validation d'un classement, politique d'aides, progression | **Non** |
| `lib/infrastructure/` | Technique : chargement du contenu, persistance locale de la progression | Toléré si nécessaire |
| `lib/ui/` | Affichage et interactions | Oui |

**Convention vérifiable** — aucun fichier de `lib/domain/` ou `lib/application/` ne
contient `import 'package:flutter/`. Contrôle :

```bash
grep -rn "package:flutter/" lib/domain lib/application && echo "VIOLATION" || echo "OK"
```

Corollaire pratique : les tests du moteur sont des tests Dart purs, sans
`WidgetTester` ni `pumpWidget`.

## 5. Conventions vérifiables

**TDD** — le développement se fait test d'abord. Un comportement du moteur s'écrit
en test avant d'être implémenté.

**Imports** — toujours `package:reading_game/` ; jamais de chemins relatifs :

```dart
// ✅
import 'package:reading_game/domain/models/word.dart';
// ❌
import '../../domain/models/word.dart';
```

**Nommage** — commentaires en français ; symboles (variables, méthodes, classes) en
anglais et explicites.

**Immutabilité** — les modèles sont immutables (`final`). Modification via
`copyWith()`, jamais de mutation directe.

**Sérialisation** — chaque modèle chargé depuis le contenu ou persisté implémente
`toJson()` et `fromJson()`.

**Injection de dépendances** — toujours par constructeur ; pas de singleton appelé
directement dans la logique métier. En particulier, le moteur reçoit sa source de
contenu et sa persistance, il ne les construit pas.

**Aléa** — jamais de `Random()` construit dans la logique de jeu : injecter un
`Random` (graine fixée en test). Sans cela le tirage des mots n'est pas testable.

**Chaînes d'interface** — centralisées dans `lib/ui/strings/ui_strings_fr.dart`
(à créer dès la première chaîne affichée). À ne pas confondre avec le contenu
pédagogique, voir §6.

**Grep avant de créer** — chercher si un widget, service ou modèle similaire existe
déjà avant d'en créer un nouveau.

## 6. Contenu pédagogique

Les mots, familles, niveaux et textes d'histoire sont **des données, pas du code**.
Ils vivent dans `assets/content/` en JSON et sont chargés par `lib/infrastructure/`.

Raison : le contenu doit pouvoir évoluer sans recompilation, être relu par un
enseignant ou un parent, et le dépôt étant destiné à l'open source, c'est le point
d'entrée le plus accessible pour une contribution extérieure.

Ne jamais coder en dur une liste de mots dans un widget ou dans le moteur.

Deux règles issues de la spécification, à respecter dans les données comme dans le
moteur :
- Les mots **ambigus** (raisonnablement classables dans plusieurs familles présentes
  à la même étape) sont à proscrire.
- Toutes les familles d'une étape acceptent leurs mots, mais seule la famille liée à
  la direction choisie fait avancer.

## 7. Documentation

| Fichier | Contenu |
|---|---|
| `docs/current.md` | État courant, version, travail en cours |
| `docs/versions.md` | Historique des versions et procédure de versioning |
| `docs/TODO.md` | Backlog |
| `docs/Specification_jeu_decouverte_lecture.md` | Cadrage fonctionnel du jeu |
