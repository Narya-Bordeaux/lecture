# État courant

**Version : 0.2.0+4** — 20 septembre 2026

## Où en est le projet

Le moteur de jeu existe et est testé, sans interface. La spécification est en
version de travail 0.5. `lib/main.dart` est toujours le squelette généré par
`flutter create` : rien n'est encore affiché à l'écran.

Le dépôt est prêt pour une éventuelle publication en open source.

## Chantier en cours

**Niveau test « Grisbie va à la plage »** — moteur et contenu livrés, interface à
faire. C'est le prochain pas : afficher une étape, permettre le glisser-déposer,
montrer les aides et les destinations ouvertes.

Le moteur étant indépendant de Flutter, l'interface ne fera que l'appeler et
afficher son état ; aucune règle de jeu ne doit être réimplémentée dedans.

## Dernières modifications

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
