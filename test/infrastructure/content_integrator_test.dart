import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/narrative.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/infrastructure/content/content_integrator.dart';
import 'package:grisbie/infrastructure/content/content_repository.dart';

import '../support/disk_content.dart';
import '../support/memory_content.dart';
import '../support/stage_builders.dart' as build;

/// « Intégrer au dépôt » : verser une aventure dans `assets/content/`, pour
/// qu'elle soit jouable à la compilation suivante.
///
/// Le dossier du dépôt est la **base** : ses listes et ses lexiques sont ceux
/// que l'aventure complète, ou corrige là où ils vivent. Et rien ne s'écrit
/// tant qu'un contrôle échoue — un dépôt à moitié modifié serait pire qu'un
/// refus.

/// Une copie en mémoire de `assets/content/`, images comprises.
MemoryContentFolder repositoryFolder() {
  final folder = MemoryContentFolder();
  final root = Directory('assets/content');
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File) continue;
    final path = entity.path
        .replaceAll(r'\', '/')
        .substring('assets/content/'.length);
    if (path.startsWith('pictures/')) {
      folder.bytes[path] = entity.readAsBytesSync();
      folder.files[path] = '<image>';
    } else {
      folder.files[path] = entity.readAsStringSync();
    }
  }
  return folder;
}

void main() {
  late Adventure delivered;

  setUpAll(() async => delivered = await loadRealAdventure());

  group('Ce qui s\'intègre', () {
    test('l\'aventure modifiée remplace l\'ancienne, et le dépôt se recharge',
        () async {
      final folder = repositoryFolder();
      final start = delivered.startStage;
      final edited = delivered.withStage(
        start.copyWith(
          narrative: const Narrative(onArrival: 'Par où partir ?'),
        ),
      );

      await ContentIntegrator(folder: folder).integrate(edited);

      // Le contrôle qui compte : le jeu, strict, ouvre ce qui a été versé.
      final reloaded = await ContentRepository(source: folder)
          .loadAdventure(delivered.id);
      expect(reloaded.startStage.narrative.onArrival, 'Par où partir ?');
    });

    test('une aventure neuve est déclarée au sommaire', () async {
      final folder = repositoryFolder();
      final copy = Adventure(
        id: 'grisbie_essai',
        title: 'Grisbie à l\'essai',
        startStageId: delivered.startStageId,
        stages: delivered.stages,
        opening: delivered.opening,
        coverAsset: delivered.coverAsset,
      );

      final written = await ContentIntegrator(folder: folder).integrate(copy);

      expect(written, contains('adventures/grisbie_essai.json'));
      final reloaded = await ContentRepository(source: folder)
          .loadAdventure('grisbie_essai');
      expect(reloaded.title, 'Grisbie à l\'essai');
    });

    test('ce que l\'aventure ne touche pas n\'est pas réécrit', () async {
      // Le dépôt possède déjà le reste : le recopier ne ferait que produire
      // des différences à relire au moment du commit.
      final folder = repositoryFolder();

      final written = await ContentIntegrator(folder: folder).integrate(
        delivered,
      );

      expect(written, isNot(contains('lexicon/transport.json')));
    });
  });

  group('Ce qui est refusé, sans rien écrire', () {
    test('un dossier qui n\'est pas celui du contenu', () async {
      // Désigner `assets/` ou la racine du dépôt par mégarde écrirait une
      // aventure là où le jeu ne la chercherait jamais.
      final folder = MemoryContentFolder(<String, String>{'README.md': '…'});

      await expectLater(
        ContentIntegrator(folder: folder).integrate(delivered),
        throwsA(
          isA<IntegrationRefused>().having(
            (refusal) => refusal.reasons.join(),
            'raisons',
            contains('index.json'),
          ),
        ),
      );
      expect(folder.files.keys, <String>['README.md']);
    });

    test('une aventure injouable', () async {
      final folder = repositoryFolder();
      final before = Map<String, String>.of(folder.files);
      final unfinished = Adventure(
        id: 'brouillon',
        title: 'Brouillon',
        startStageId: 'depart',
        stages: <String, Stage>{
          'depart': build.stage(id: 'depart', families: const <WordFamily>[]),
        },
      );

      await expectLater(
        ContentIntegrator(folder: folder).integrate(unfinished),
        throwsA(isA<IntegrationRefused>()),
      );
      expect(folder.files, before);
    });

    test('une image absente du dépôt, nommée', () async {
      // L'enfant verrait un fond uni : l'image citée doit être versée dans
      // `pictures/` avant l'aventure.
      final folder = repositoryFolder();
      final before = Map<String, String>.of(folder.files);
      final withMissingPicture = delivered.withStage(
        delivered.startStage.copyWith(
          backgroundAsset: 'pictures/gare_1790155902917.jpg',
        ),
      );

      await expectLater(
        ContentIntegrator(folder: folder).integrate(withMissingPicture),
        throwsA(
          isA<IntegrationRefused>().having(
            (refusal) => refusal.reasons.join(),
            'raisons',
            contains('pictures/gare_1790155902917.jpg'),
          ),
        ),
      );
      expect(folder.files, before);
    });

    test('le refus dit dans quel dossier verser l image', () async {
      // Chaque aventure range ses images dans `pictures/<son id>/`.
      final withMissingPicture = delivered.withStage(
        delivered.startStage.copyWith(backgroundAsset: 'pictures/absente.jpg'),
      );

      await expectLater(
        ContentIntegrator(folder: repositoryFolder())
            .integrate(withMissingPicture),
        throwsA(
          isA<IntegrationRefused>().having(
            (refusal) => refusal.reasons.join(),
            'raisons',
            contains('assets/content/pictures/${delivered.id}/'),
          ),
        ),
      );
    });
  });
}
