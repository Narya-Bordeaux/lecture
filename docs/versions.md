# Versions

## Procédure de versioning — obligatoire

Toute session livrant une fonctionnalité ou une correction donne lieu à un
incrément de version. Une session qui ne touche qu'à la documentation de travail
(`current.md`, `TODO.md`) n'en demande pas.

### Format

`majeur.mineur.correctif+build` — par exemple `0.3.1+12`.

| Niveau | Quand l'incrémenter | Exemple |
|---|---|---|
| Majeur | Refonte, rupture de compatibilité des données sauvegardées | 0.9.0 → 1.0.0 |
| Mineur | Nouvelle fonctionnalité | 0.3.1 → 0.4.0 |
| Correctif | Correction de bug, ou nettoyage structurel sans fonctionnalité nouvelle | 0.3.0 → 0.3.1 |
| Build | **À chaque** incrément, quel qu'en soit le niveau. Jamais réinitialisé | +11 → +12 |

Tant que le jeu n'est pas jouable de bout en bout, la version reste en `0.x`.

### Les quatre fichiers à mettre à jour

Un incrément de version touche ces quatre fichiers, toujours, dans cet ordre :

1. `pubspec.yaml` — la ligne `version:`
2. `docs/versions.md` — une nouvelle entrée, la plus récente en haut
3. `docs/current.md` — la version en en-tête et la section « Dernières modifications »
4. `CLAUDE.md` — la ligne « Version actuelle » du §1

Contrôle rapide avant de clore une session, les quatre doivent concorder :

```bash
grep -rn "^version:" pubspec.yaml && grep -rn "Version actuelle" CLAUDE.md && head -3 docs/current.md
```

### Règle d'écriture

**Une entrée versionnée par incrément**, jamais d'ajout en vrac à l'entrée
précédente. La section « Dernières modifications » de `current.md` ne conserve que
les 2 ou 3 dernières versions ; les plus anciennes ne vivent que dans ce fichier.

---

## Historique

### 0.1.1+2 — 20 septembre 2026 — Retrait de la plateforme iOS

iOS n'est pas une plateforme visée et aucun compte développeur Apple n'est ouvert.
Le dossier `ios/` représentait 27 des 69 fichiers suivis, entièrement générés et
jamais personnalisés.

- Suppression du dossier `ios/`.
- `.metadata` : retrait de l'entrée de migration `ios` et du fichier `ios` de
  `unmanaged_files`. Édité à la main faute de Flutter dans l'environnement cloud,
  alors que ce fichier est normalement maintenu par l'outil.
- `docs/TODO.md` : commande de régénération consignée, pour que le retour d'iOS
  reste trivial.

### 0.1.0+1 — 20 septembre 2026 — Mise en place du cadre de travail

Préparation du dépôt en vue d'une éventuelle publication en open source.

- `.gitignore` durci : `.vscode/`, `.env` et variantes avec exception
  `.env.example`, `.claude/settings.local.json`.
- `CLAUDE.md` créé : périmètre du projet, environnement, conventions vérifiables et
  règle de séparation moteur / interface.
- `docs/current.md`, `docs/versions.md` et `docs/TODO.md` créés.
- Version ramenée de `1.0.0+1` (valeur générée par `flutter create`) à `0.1.0+1`,
  le code applicatif n'étant pas encore écrit.

Aucun code applicatif livré à ce stade.
