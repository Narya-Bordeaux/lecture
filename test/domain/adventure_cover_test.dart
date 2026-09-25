import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/adventure_opening.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word_list_catalog.dart';

import '../support/stage_builders.dart';

/// La vignette : l'image qui represente l'aventure dans la roue de l'accueil.

Adventure withoutCover() {
  return Adventure(
    id: 'essai',
    title: 'Essai',
    startStageId: 'plage',
    stages: <String, Stage>{'plage': ending(id: 'plage', location: 'La plage')},
  );
}

Adventure covered() => withoutCover().withCover('pictures/vignette.jpg');

/// Les anomalies qui concernent la vignette.
List<ContentIssue> coverIssues(Adventure adventure) => adventure
    .validate()
    .where((issue) => issue.message.contains('vignette'))
    .toList();

void main() {
  group('Lire et ecrire', () {
    test('le fichier d aventure porte la vignette', () {
      final adventure = Adventure.fromJson(
        <String, dynamic>{
          'id': 'essai',
          'title': 'Essai',
          'cover': 'pictures/vignette.jpg',
          'startStageId': 'plage',
          'stages': <dynamic>[ending(id: 'plage', location: 'La plage').toJson()],
        },
        lists: WordListCatalog.empty,
      );

      expect(adventure.coverAsset, 'pictures/vignette.jpg');
      expect(adventure.toJson()['cover'], 'pictures/vignette.jpg');
    });

    test('sans vignette, le champ est absent du fichier', () {
      expect(withoutCover().toJson().containsKey('cover'), isFalse);
    });
  });

  group('Une vignette obligatoire', () {
    test('sans vignette, l aventure n est pas complete', () {
      final issues = coverIssues(withoutCover());

      expect(issues, hasLength(1));
      expect(issues.single.severity, IssueSeverity.incomplete);
      // Elle vise l'aventure entiere, pas un lieu.
      expect(issues.single.stageId, isNull);
      expect(withoutCover().readiness, ContentReadiness.incomplete);
    });

    test('un chemin vide ne vaut pas une vignette', () {
      expect(coverIssues(withoutCover().withCover('  ')), hasLength(1));
    });

    test('avec sa vignette, l aventure est jouable', () {
      expect(coverIssues(covered()), isEmpty);
      expect(covered().readiness, ContentReadiness.playable);
    });

    test('la vignette fait partie des images a trouver dans le depot', () {
      expect(covered().picturePaths, contains('pictures/vignette.jpg'));
    });
  });

  group('Modifier sans perdre la vignette', () {
    test('elle se pose et se retire', () {
      expect(covered().coverAsset, 'pictures/vignette.jpg');
      expect(covered().withCover(null).coverAsset, isNull);
    });

    test('remplacer un lieu la garde', () {
      final edited = covered().withStage(
        ending(id: 'plage', location: 'La grande plage'),
      );

      expect(edited.coverAsset, 'pictures/vignette.jpg');
    });

    test('changer la page de garde la garde', () {
      final edited = covered().withOpening(
        const AdventureOpening(imageAsset: 'pictures/garde.jpg', text: 'Il etait une fois.'),
      );

      expect(edited.coverAsset, 'pictures/vignette.jpg');
    });

    test('changer la structure la garde', () {
      final edited = AdventureBuilder(covered()).reopen('plage');

      expect(edited.coverAsset, 'pictures/vignette.jpg');
    });

    test('la page de garde, elle, garde sa propre image', () {
      final edited = withoutCover()
          .withOpening(const AdventureOpening(imageAsset: 'pictures/garde.jpg', text: 'Texte.'))
          .withCover('pictures/vignette.jpg');

      expect(edited.opening!.imageAsset, 'pictures/garde.jpg');
    });
  });
}
