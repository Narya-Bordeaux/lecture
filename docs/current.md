# État courant

**Version : 0.1.0+1** — 20 septembre 2026

## Où en est le projet

Phase de conception. La spécification fonctionnelle est en version de travail 0.4 et
sert de base commune. Le code applicatif n'existe pas encore : `lib/main.dart` est
toujours le squelette généré par `flutter create`, et `test/widget_test.dart` le test
de démonstration associé.

Le dépôt vient d'être préparé en vue d'une éventuelle publication en open source.

## Chantier en cours

Mise en place du cadre de travail (documentation, conventions, versioning). Aucun
chantier fonctionnel ouvert.

## Dernières modifications

### 0.1.0+1 — Mise en place du cadre de travail
- Durcissement du `.gitignore` en vue d'une publication open source : `.vscode/`,
  `.env` et variantes (avec exception `.env.example`), `.claude/settings.local.json`.
- Ajout de `CLAUDE.md` : conventions du projet et règle de séparation moteur /
  interface.
- Ajout de `docs/current.md`, `docs/versions.md` et `docs/TODO.md`.
- Passage de la version générée par défaut (1.0.0+1) à 0.1.0+1, le projet n'ayant
  pas encore de code applicatif.

## Décisions prises

- **Plateformes** : Web, Android, Windows. iOS et macOS ne sont pas visés, bien que
  le dossier `ios/` soit encore présent dans le dépôt.
- **Pas de serveur** : la progression reste sur l'appareil. Le public étant mineur,
  aucune donnée personnelle ne sort de la machine. Un backend n'est pas exclu à
  terme, mais ce serait une décision à part entière.
- **Contenu pédagogique séparé du code** : les mots, familles et niveaux vivront dans
  `assets/content/` en JSON.

## Points ouverts

Les questions fonctionnelles non tranchées sont listées en fin de
`Specification_jeu_decouverte_lecture.md` et ne sont pas reprises ici.
