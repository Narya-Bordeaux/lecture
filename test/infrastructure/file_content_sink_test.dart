import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_game/domain/models/adventure.dart';
import 'package:reading_game/infrastructure/content/content_repository.dart';
import 'package:reading_game/infrastructure/content/content_writer.dart';
import 'package:reading_game/infrastructure/content/file_content_sink.dart';
import 'package:reading_game/infrastructure/content/file_content_source.dart';

import '../support/disk_content.dart';

/// Un dossier de travail vide, efface a la fin du test.
Directory makeTempDirectory() {
  final directory = Directory.systemTemp.createTempSync('lecture_');
  addTearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });
  return directory;
}

/// Recopie le contenu livre dans [target], comme le ferait l'outil d'auteur en
/// partant de l'existant.
void copyDeliveredContent(Directory target) {
  final source = Directory('assets/content');
  for (final entity in source.listSync(recursive: true)) {
    if (entity is! File) continue;
    final relative = entity.path.substring(source.path.length + 1);
    final destination = File('${target.path}/$relative');
    destination.parent.createSync(recursive: true);
    entity.copySync(destination.path);
  }
}

void main() {
  const adventurePath = 'adventures/grisbie_plage.json';

  group('Ecriture sur le disque', () {
    test('le fichier arrive a l\'emplacement demande', () async {
      final directory = makeTempDirectory();

      await FileContentSink(directory: directory.path).writeFile(
        'index.json',
        '{}',
      );

      expect(File('${directory.path}/index.json').readAsStringSync(), '{}');
    });

    test('les dossiers manquants sont crees', () async {
      // « adventures/ » n'existe pas encore dans un dossier vierge : sans
      // creation prealable, l'enregistrement echouerait sur la premiere
      // aventure d'une installation neuve.
      final directory = makeTempDirectory();

      await FileContentSink(directory: directory.path).writeFile(
        'adventures/nouvelle.json',
        '{}',
      );

      expect(
        File('${directory.path}/adventures/nouvelle.json').existsSync(),
        isTrue,
      );
    });

    test('un fichier existant est remplace, pas complete', () async {
      final directory = makeTempDirectory();
      final sink = FileContentSink(directory: directory.path);

      await sink.writeFile('index.json', '{"premier": true}');
      await sink.writeFile('index.json', '{"second": true}');

      expect(
        File('${directory.path}/index.json').readAsStringSync(),
        '{"second": true}',
      );
    });
  });

  group('Aller-retour par le disque', () {
    late Adventure delivered;

    setUpAll(() async => delivered = await loadRealAdventure());

    test('ce que l\'outil enregistre, le jeu le recharge', () async {
      // Le test de bout en bout : un vrai dossier, un vrai fichier ecrit, et
      // le chargement du jeu par-dessus. Les tests precedents travaillaient en
      // memoire et ne voyaient rien des chemins ni des dossiers manquants.
      final directory = makeTempDirectory();
      copyDeliveredContent(directory);

      await ContentWriter(
        sink: FileContentSink(directory: directory.path),
      ).writeAdventure(delivered, path: adventurePath);

      final reloaded = await ContentRepository(
        source: FileContentSource(directory: directory.path),
      ).loadAdventure(delivered.id);

      expect(reloaded.validate(), isEmpty);
      expect(
        reloaded.stages.keys.toList(),
        delivered.stages.keys.toList(),
      );
      expect(
        reloaded.startStage.families.first.area,
        delivered.startStage.families.first.area,
      );
    });

    test('le sommaire reecrit reste lisible par le jeu', () async {
      final directory = makeTempDirectory();
      copyDeliveredContent(directory);

      final index = await buildDiskRepository().loadIndex();
      await ContentWriter(
        sink: FileContentSink(directory: directory.path),
      ).writeIndex(index);

      final reloaded = await ContentRepository(
        source: FileContentSource(directory: directory.path),
      ).loadIndex();

      expect(reloaded.lexiconFiles, index.lexiconFiles);
      expect(reloaded.charactersFile, index.charactersFile);
      expect(
        reloaded.adventures.map((entry) => entry.id),
        index.adventures.map((entry) => entry.id),
      );
    });

    test('une aventure ecrite dans un dossier vierge se recharge', () async {
      // Cas d'une installation neuve : rien n'existe, tout est cree.
      final directory = makeTempDirectory();
      final writer = ContentWriter(
        sink: FileContentSink(directory: directory.path),
      );

      // Le lexique et les personnages viennent du contenu livre : l'aventure
      // ne fait que les citer.
      copyDeliveredContent(directory);
      File('${directory.path}/$adventurePath').deleteSync();

      await writer.writeAdventure(delivered, path: adventurePath);

      final reloaded = await ContentRepository(
        source: FileContentSource(directory: directory.path),
      ).loadAdventure(delivered.id);

      expect(reloaded.title, delivered.title);
    });
  });
}
