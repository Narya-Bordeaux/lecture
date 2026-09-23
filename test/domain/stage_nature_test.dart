import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';

import '../support/stage_builders.dart';

/// Ce que l'enfant fait dans un lieu, et ce que l'auteur sait de son aventure.
///
/// **La nature d'un lieu se lit dans sa structure.** Arrive a la gare,
/// l'enfant range dans plusieurs listes, ou fait un tri unique, ou lit la fin
/// de la journee. Un lieu qu'on vient de creer n'est encore rien de tout cela :
/// c'est a l'auteur de le dire, sur sa carte.

const RelativeArea _someArea =
    RelativeArea(left: 0.1, top: 0.5, width: 0.2, height: 0.2);

void main() {
  group('La nature d\'un lieu', () {
    test('un lieu sans famille ni fin est a definir', () {
      expect(
        stage(id: 'gare', families: const <WordFamily>[]).nature,
        StageNature.undefined,
      );
    });

    test('des familles qui menent toutes ailleurs : plusieurs listes', () {
      final gare = stage(id: 'gare', families: <WordFamily>[
        family(id: 'train', label: 'Le train', destination: 'plage'),
        family(id: 'bus', label: 'Le bus', destination: 'marche'),
      ]);

      expect(gare.nature, StageNature.sorting);
    });

    test('une famille sans destination fait un tri unique', () {
      final boutique = stage(id: 'boutique', families: <WordFamily>[
        family(id: 'a_manger', label: 'Ce qui se mange', destination: 'plage'),
        family(id: 'autre', label: 'Autre chose'),
      ]);

      expect(boutique.nature, StageNature.singleSort);
    });

    test('une fin declaree est une fin', () {
      expect(ending(id: 'plage').nature, StageNature.ending);
    });
  });

  group('Ou en est une aventure', () {
    Adventure adventureOf(Stage start, [List<Stage> others = const <Stage>[]]) {
      return Adventure(
        id: 'essai',
        title: 'Essai',
        startStageId: start.id,
        stages: <String, Stage>{
          start.id: start,
          for (final other in others) other.id: other,
        },
      );
    }

    test('sans anomalie, elle est jouable', () {
      final adventure = adventureOf(
        stage(id: 'maison', families: <WordFamily>[
          family(
            id: 'en_bus',
            label: 'En bus',
            words: <Word>[word('ticket')],
            destination: 'plage',
          ),
        ]),
        <Stage>[ending(id: 'plage')],
      );

      expect(adventure.readiness, ContentReadiness.playable);
    });

    test('avec des manques seulement, elle n\'est pas complete', () {
      // Un lieu cree, pas encore defini : du travail qui reste, pas une faute.
      final adventure = adventureOf(
        stage(id: 'maison', families: const <WordFamily>[]),
      );

      expect(adventure.readiness, ContentReadiness.incomplete);
    });

    test('une seule faute suffit a la dire fausse', () {
      // « bus » dans « En bus » se classerait en comparant les lettres.
      final adventure = adventureOf(
        stage(id: 'maison', families: <WordFamily>[
          family(
            id: 'en_bus',
            label: 'En bus',
            words: <Word>[word('bus')],
            destination: 'plage',
          ),
        ]),
        <Stage>[ending(id: 'plage')],
      );

      expect(adventure.readiness, ContentReadiness.wrong);
    });

    test('l\'etat se deduit des anomalies, sans autre regle', () {
      expect(
        ContentReadiness.of(const <ContentIssue>[]),
        ContentReadiness.playable,
      );
      expect(
        ContentReadiness.of(const <ContentIssue>[
          ContentIssue.incomplete('a'),
          ContentIssue.wrong('b'),
        ]),
        ContentReadiness.wrong,
      );
    });
  });

  group('Une famille sans zone sur un lieu illustre', () {
    Stage illustratedStation({RelativeArea? trainArea}) {
      return stage(id: 'gare', families: <WordFamily>[
        family(
          id: 'train',
          label: 'Le train',
          words: <Word>[word('quai')],
          destination: 'plage',
          area: trainArea,
        ),
      ]).copyWith(backgroundAsset: 'pictures/gare.jpg');
    }

    test('est signalee, comme un travail qui reste', () {
      // Dans le jeu, une famille sans zone n'est pas affichee : ses mots ne se
      // poseraient nulle part, et le lieu ne se terminerait jamais.
      final issues = illustratedStation().validate();
      final missing = issues.where((i) => i.message.contains('zone'));

      expect(missing, hasLength(1));
      expect(missing.single.severity, IssueSeverity.incomplete);
      expect(missing.single.familyId, 'train');
    });

    test('ne l\'est plus une fois la zone posee', () {
      final issues = illustratedStation(trainArea: _someArea).validate();

      expect(issues.where((i) => i.message.contains('zone')), isEmpty);
    });

    test('un lieu sans illustration n\'est pas concerne', () {
      // Les zones se calent sur l'image : sans elle, il n'y a rien a caler
      // encore. C'est aussi ce qui laisse jouable le contenu livre, dont la
      // gare et la boutique attendent leur decor.
      final bare = stage(id: 'gare', families: <WordFamily>[
        family(
          id: 'train',
          label: 'Le train',
          words: <Word>[word('quai')],
          destination: 'plage',
        ),
      ]);

      expect(bare.validate().where((i) => i.message.contains('zone')), isEmpty);
    });
  });
}
