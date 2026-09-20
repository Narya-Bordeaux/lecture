# État courant

**Version : 0.1.2+3** — 20 septembre 2026

## Où en est le projet

Phase de conception. La spécification fonctionnelle est en version de travail 0.4 et
sert de base commune. Le code applicatif n'existe pas encore : `lib/main.dart` est
toujours le squelette généré par `flutter create`, et `test/widget_test.dart` le test
de démonstration associé.

Le dépôt vient d'être préparé en vue d'une éventuelle publication en open source.

## Chantier en cours

Mise en place du cadre de travail (documentation, conventions, versioning,
outillage). Aucun chantier fonctionnel ouvert.

Prochaine étape naturelle : répondre aux questions ouvertes de la spécification,
puis définir le format du contenu pédagogique avant d'écrire le moteur.

## Dernières modifications

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
- **Contenu pédagogique séparé du code** : les mots, familles et niveaux vivront dans
  `assets/content/` en JSON.

## Points ouverts

Les questions fonctionnelles non tranchées sont listées en fin de
`Specification_jeu_decouverte_lecture.md` et ne sont pas reprises ici.
