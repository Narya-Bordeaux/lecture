# État courant

**Version : 0.4.0+6** — 20 septembre 2026

## Où en est le projet

**Le niveau test est jouable.** L'étape de départ s'affiche sur l'illustration
`Grisbie_plage2.jpg` : six mots en haut, trois zones translucides posées sur le
bus, la voiture et le sentier, glisser-déposer, aides et bouton de départ.
Chaque famille puise dans une liste de dix mots, et un mot bien classé est
remplacé sur place par un mot de la réserve. La spécification est en version de
travail 0.6.

Le rendu visuel n'a jamais été vu : les builds sont impossibles en session cloud.
Seul le comportement est prouvé, par 65 tests.

## Chantier en cours

**Niveau test « Grisbie va à la plage »** — reste à juger le rendu réel sur
appareil, puis à traiter la suite du parcours : la gare n'a pas d'illustration et
ses zones n'ont pas de position, l'étape s'y affiche donc sur fond uni.

Deux réglages attendent un avis : l'**objectif** de cinq mots par famille, et le
**tirage libre** qui peut ne proposer aucun mot d'une famille donnée.

## Dernières modifications

### 0.4.0+6 — Réserve de dix mots par famille
- Trois listes de dix mots ; six sont proposés à la fois, les autres attendent.
- Un mot bien classé est remplacé **sur place** par un mot de la réserve ; les
  autres mots ne bougent pas. Un mot mal classé ne déclenche rien.
- Objectif réglable par famille (`goal`), fixé à 5 : sans lui, il faudrait près
  de trente classements pour ouvrir un chemin.
- La zone affiche l'avancement vers l'objectif (« 3 / 5 »), pas vers la réserve.
- 65 tests au vert.

### 0.3.0+5 — Interface du niveau test
- Décor plein écran, six étiquettes en grille 2 × 3, trois zones translucides
  ancrées sur le bus, la voiture et le sentier.
- Glisser-déposer : le mot juste se range dans sa zone, le mot faux revient à sa
  case en tremblant et débloque son découpage syllabique.
- Bouton « Partir » en bas, une fois une famille complète.
- Contenu revu : famille « En bus » au lieu de « En train », mots choisis pour
  qu'aucun ne se devine par le nom de sa famille.
- 50 tests, dont l'étape réelle montée sur trois formats d'écran.

### 0.2.0+4 — Moteur d'étape et niveau test
- Domaine : `Word`, `WordFamily`, `Stage`, `Adventure`, `HintPolicy`, `Hint`.
- Moteur `StageEngine` : placement, refus immédiat, comptage des erreurs par mot,
  déblocage des aides, complétion d'une famille, ouverture des destinations,
  départ à l'initiative de l'enfant.
- Contenu `assets/content/adventures/grisbie_beach.json` : trois chemins au départ,
  une étape imbriquée dans la gare, la plage en arrivée.
- 31 tests au vert, `flutter analyze` sans erreur.
- Spécification mise à jour (v0.5) d'après les décisions prises en session.

### 0.1.2+3 — Flutter disponible dans l'environnement cloud
- Hook de démarrage de session installant le SDK Flutter 3.47.5, version épinglée et
  archive vérifiée. `flutter analyze` et `flutter test` sont désormais exécutables en
  session cloud ; les builds ne le sont toujours pas.
- Démarrage à froid 1 min 34 s, reprise à chaud 0,9 s.

### 0.1.1+2 — Retrait de la plateforme iOS
- Suppression du dossier `ios/`, entièrement généré et jamais personnalisé, pour une
  plateforme non visée. Commande de régénération consignée dans `docs/TODO.md`.
- `.metadata` mis en cohérence : entrée de migration `ios` retirée.

### 0.1.0+1 — Mise en place du cadre de travail
- Durcissement du `.gitignore` en vue d'une publication open source : `.vscode/`,
  `.env` et variantes (avec exception `.env.example`), `.claude/settings.local.json`.
- Ajout de `CLAUDE.md` : conventions du projet et règle de séparation moteur /
  interface.
- Ajout de `docs/current.md`, `docs/versions.md` et `docs/TODO.md`.
- Passage de la version générée par défaut (1.0.0+1) à 0.1.0+1, le projet n'ayant
  pas encore de code applicatif.

## Décisions prises

- **Plateformes** : Web, Android, Windows. iOS et macOS ne sont pas visés, et `ios/`
  a été supprimé du dépôt en 0.1.1. Seul `android/` est configuré à ce jour.
- **Pas de serveur** : la progression reste sur l'appareil. Le public étant mineur,
  aucune donnée personnelle ne sort de la machine. Un backend n'est pas exclu à
  terme, mais ce serait une décision à part entière.
- **Contenu pédagogique séparé du code** : les mots, familles et niveaux vivent dans
  `assets/content/` en JSON.
- **Le classement est libre, le départ est choisi** : compléter une famille ouvre sa
  destination sans y envoyer l'enfant. Plusieurs destinations peuvent être ouvertes
  en même temps ; l'enfant part quand il le décide.
- **Aides automatiques** : syllabes dès la 1ʳᵉ erreur sur un mot, illustration à la
  5ᵉ. L'écart est délibéré — le découpage aide à déchiffrer, l'illustration donne
  presque la réponse.
- **Étapes imbriquées** : une destination atteinte ouvre une étape de même nature,
  avec ses propres familles. Le modèle est récursif, un seul moteur sert partout.

## Points ouverts

Les questions fonctionnelles non tranchées sont listées en fin de
`Specification_jeu_decouverte_lecture.md` et ne sont pas reprises ici.
