import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifie que tout fichier de `assets/` est bien declare dans `pubspec.yaml`.
///
/// Ce test repond a une panne reelle : les fichiers de contenu avaient ete
/// repartis en sous-dossiers, mais `pubspec.yaml` ne declarait que l'un d'eux.
/// Flutter **n'embarque pas les sous-dossiers** — une entree terminee par `/`
/// ne prend que les fichiers de ce repertoire precis. L'application se
/// compilait, les tests passaient (ils lisent le disque, pas le bundle), et le
/// jeu affichait « Le jeu n'a pas pu s'ouvrir » sur l'appareil.
///
/// Aucun autre test ne peut attraper cela : c'est le seul qui regarde ce qui
/// sera reellement livre.

/// Les repertoires declares dans la section `assets:` du pubspec.
Set<String> readDeclaredAssetDirectories() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  final declared = <String>{};

  var inAssets = false;
  for (final line in lines) {
    final trimmed = line.trim();

    if (trimmed == 'assets:') {
      inAssets = true;
      continue;
    }
    if (inAssets) {
      // La section s'arrete au premier element qui n'est pas de la liste.
      if (!trimmed.startsWith('- ')) {
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        break;
      }
      declared.add(trimmed.substring(2).trim());
    }
  }

  return declared;
}

void main() {
  test('chaque fichier de assets/ est declare dans pubspec.yaml', () {
    final declared = readDeclaredAssetDirectories();
    expect(declared, isNotEmpty, reason: 'Aucun asset declare');

    final missing = <String>[];
    for (final entity in Directory('assets').listSync(recursive: true)) {
      if (entity is! File) continue;

      final path = entity.path.replaceAll(r'\', '/');
      // Un fichier est couvert par la declaration de son propre repertoire,
      // ou par une declaration nominative.
      final directory = '${path.substring(0, path.lastIndexOf('/'))}/';
      if (!declared.contains(directory) && !declared.contains(path)) {
        missing.add(path);
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'Ces fichiers ne seront pas embarques dans l\'application, et '
          'manqueront a l\'execution sans erreur de compilation :\n'
          '${missing.join('\n')}\n'
          'Ajouter leur repertoire a la section assets: du pubspec.',
    );
  });
}
