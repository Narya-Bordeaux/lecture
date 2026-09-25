import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';

import '../support/stage_builders.dart';

/// Un chemin qui ramene a un lieu deja traverse : l'enfant peut tourner en rond.
///
/// **Ce n'est pas interdit.** L'auteur garde la possibilite de faire rejoindre
/// a un trajet n'importe quel lieu deja ecrit ; l'outil le **signale**, et
/// c'est tout. D'ou une troisieme sorte d'anomalie, *a verifier*, qui ne
/// bloque ni le jeu ni la mention « jouable ».

/// Un trajet menant a [to], avec de quoi jouer.
WordFamily trip(String id, String to) {
  return family(
    id: id,
    label: 'Trajet $id',
    words: <Word>[word('mot_$id')],
    destination: to,
  );
}

Adventure adventureOf(List<Stage> stages) {
  return Adventure(
    id: 'essai',
    title: 'Essai',
    coverAsset: 'pictures/vignette.jpg',
    startStageId: stages.first.id,
    stages: <String, Stage>{for (final stage in stages) stage.id: stage},
  );
}

List<ContentIssue> loopsIn(Adventure adventure) {
  return adventure
      .validate()
      .where((issue) => issue.severity == IssueSeverity.warning)
      .toList(growable: false);
}

void main() {
  test('un parcours sans retour n\'est pas signale', () {
    final adventure = adventureOf(<Stage>[
      stage(drawCount: 1, id: 'maison', families: <WordFamily>[trip('bus', 'gare')]),
      stage(drawCount: 1, id: 'gare', families: <WordFamily>[trip('train', 'plage')]),
      ending(id: 'plage'),
    ]);

    expect(loopsIn(adventure), isEmpty);
  });

  test('deux chemins vers la meme fin ne sont pas une boucle', () {
    final adventure = adventureOf(<Stage>[
      stage(drawCount: 1, id: 'maison', families: <WordFamily>[
        trip('bus', 'plage'),
        trip('pied', 'plage'),
      ]),
      ending(id: 'plage'),
    ]);

    expect(loopsIn(adventure), isEmpty);
  });

  test('un trajet qui ramene en arriere est signale, a verifier', () {
    final adventure = adventureOf(<Stage>[
      stage(drawCount: 1, id: 'maison', families: <WordFamily>[trip('bus', 'gare')]),
      stage(drawCount: 1, id: 'gare', families: <WordFamily>[
        trip('retour', 'maison'),
        trip('train', 'plage'),
      ]),
      ending(id: 'plage'),
    ]);

    final loops = loopsIn(adventure);
    // Les deux trajets de la boucle : l'aller et le retour.
    expect(
      loops.map((issue) => issue.familyId),
      unorderedEquals(<String>['bus', 'retour']),
    );
    expect(loops.first.message, contains('tourner en rond'));
  });

  test('un lieu qui mene a lui-meme est signale', () {
    final adventure = adventureOf(<Stage>[
      stage(drawCount: 1, id: 'maison', families: <WordFamily>[
        trip('encore', 'maison'),
        trip('bus', 'plage'),
      ]),
      ending(id: 'plage'),
    ]);

    expect(loopsIn(adventure).map((i) => i.familyId), <String>['encore']);
  });

  test('a verifier ne retire pas la mention « jouable »', () {
    final adventure = adventureOf(<Stage>[
      stage(drawCount: 1, id: 'maison', families: <WordFamily>[trip('bus', 'gare')]),
      stage(drawCount: 1, id: 'gare', families: <WordFamily>[
        trip('retour', 'maison'),
        trip('train', 'plage'),
      ]),
      ending(id: 'plage'),
    ]);

    expect(loopsIn(adventure), isNotEmpty);
    expect(adventure.readiness, ContentReadiness.playable);
  });

  test('seuls les manques et les fautes empechent de jouer', () {
    expect(
      ContentReadiness.of(const <ContentIssue>[
        ContentIssue.warning('a'),
      ]),
      ContentReadiness.playable,
    );
    expect(ContentIssue.warning('a').blocksPlay, isFalse);
    expect(ContentIssue.incomplete('a').blocksPlay, isTrue);
    expect(ContentIssue.wrong('a').blocksPlay, isTrue);
  });
}
