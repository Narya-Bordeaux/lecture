import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';

import '../support/stage_builders.dart';

/// Ce qui est **faux** ne s'arrangera pas en continuant d'ecrire ; ce qui est
/// **incomplet** est l'etat normal d'un travail en cours.
///
/// La distinction existe pour l'outil d'auteur. Une aventure en cours
/// d'ecriture est toujours invalide — le premier lieu cree n'a pas de mots,
/// aucune famille ne mene nulle part. Tout signaler en rouge donnerait un ecran
/// que l'auteur apprendrait a ignorer, et le jour ou une vraie faute s'y
/// glisserait, elle passerait inapercue.
///
/// Le classement vit dans le domaine et non dans l'interface : c'est un
/// jugement sur le contenu, pas une question d'affichage.

/// Les anomalies d'une severite donnee, dans l'aventure entiere.
List<ContentIssue> issuesOf(Adventure adventure, IssueSeverity severity) {
  return adventure
      .validate()
      .where((issue) => issue.severity == severity)
      .toList(growable: false);
}

/// Une aventure d'un seul lieu, batie autour des familles fournies.
Adventure adventureWith(
  List<WordFamily> families, {
  String start = 'depart',
}) {
  return adventureOf(
    <Stage>[stage(id: 'depart', families: families)],
    start: start,
  );
}

/// Une aventure reunissant les etapes fournies.
Adventure adventureOf(List<Stage> stages, {String start = 'depart'}) {
  return Adventure(
    id: 'essai',
    title: 'Essai',
    startStageId: start,
    stages: <String, Stage>{
      for (final stage in stages) stage.id: stage,
    },
  );
}

void main() {
  group('Ce qui est faux', () {
    test('un mot revendique par deux familles de la meme etape', () {
      final adventure = adventureWith(<WordFamily>[
        family(
          id: 'en_bus',
          label: 'En autocar',
          words: <Word>[word('ticket')],
          destination: 'depart',
        ),
        family(
          id: 'a_pied',
          label: 'A pied',
          words: <Word>[word('ticket')],
        ),
      ]);

      final wrong = issuesOf(adventure, IssueSeverity.wrong);

      // Le jeu refuserait une bonne reponse : la specification le proscrit.
      expect(wrong, hasLength(1));
      expect(wrong.single.message, contains('ticket'));
      expect(wrong.single.stageId, 'depart');
    });

    test('un mot qui apparait dans le nom de sa famille', () {
      final adventure = adventureWith(<WordFamily>[
        family(
          id: 'en_bus',
          label: 'En bus',
          words: <Word>[word('bus')],
          destination: 'depart',
        ),
      ]);

      // Il se classerait en comparant les lettres, sans etre compris.
      final wrong = issuesOf(adventure, IssueSeverity.wrong);
      expect(wrong, hasLength(1));
      expect(wrong.single.familyId, 'en_bus');
    });

    test('deux zones de depot qui se chevauchent', () {
      final adventure = adventureWith(<WordFamily>[
        family(
          id: 'en_bus',
          label: 'En autocar',
          words: <Word>[word('ticket')],
          destination: 'depart',
          area: const RelativeArea(left: .1, top: .2, width: .4, height: .3),
        ),
        family(
          id: 'a_pied',
          label: 'A pied',
          words: <Word>[word('sentier')],
          area: const RelativeArea(left: .2, top: .3, width: .4, height: .3),
        ),
      ]);

      // Le depot deviendrait ambigu au doigt.
      expect(issuesOf(adventure, IssueSeverity.wrong), hasLength(1));
    });

    test('une etape de depart introuvable', () {
      final adventure = adventureWith(
        <WordFamily>[
          family(
            id: 'en_bus',
            label: 'En autocar',
            words: <Word>[word('ticket')],
            destination: 'depart',
          ),
        ],
        start: 'nulle_part',
      );

      // L'aventure ne s'ouvrirait pas du tout.
      final wrong = issuesOf(adventure, IssueSeverity.wrong);
      expect(wrong, isNotEmpty);
      expect(wrong.first.message, contains('nulle_part'));
    });
  });

  group('Ce qui est seulement incomplet', () {
    test('une famille sans aucun mot', () {
      final adventure = adventureWith(<WordFamily>[
        family(
          id: 'en_bus',
          label: 'En autocar',
          words: const <Word>[],
          destination: 'depart',
        ),
      ]);

      // On vient de la creer : c'est le cas normal.
      expect(issuesOf(adventure, IssueSeverity.wrong), isEmpty);
      expect(issuesOf(adventure, IssueSeverity.incomplete), hasLength(1));
    });

    test('un mot sans decoupage syllabique', () {
      final adventure = adventureWith(<WordFamily>[
        family(
          id: 'en_bus',
          label: 'En autocar',
          words: <Word>[word('ticket', const <String>[])],
          destination: 'depart',
        ),
      ]);

      // Le mot est pose, ses syllabes restent a taper.
      expect(issuesOf(adventure, IssueSeverity.wrong), isEmpty);
      final incomplete = issuesOf(adventure, IssueSeverity.incomplete);
      expect(incomplete, hasLength(1));
      expect(incomplete.single.wordText, 'ticket');
    });

    test('une etape dont aucune famille ne mene ailleurs', () {
      final adventure = adventureWith(<WordFamily>[
        family(
          id: 'en_bus',
          label: 'En autocar',
          words: <Word>[word('ticket')],
        ),
      ]);

      // Tout lieu neuf est un cul-de-sac jusqu'a ce qu'on le relie.
      expect(issuesOf(adventure, IssueSeverity.wrong), isEmpty);
      expect(issuesOf(adventure, IssueSeverity.incomplete), hasLength(1));
    });

    test('une destination annoncee avant que le lieu existe', () {
      final adventure = adventureWith(<WordFamily>[
        family(
          id: 'en_bus',
          label: 'En autocar',
          words: <Word>[word('ticket')],
          destination: 'marche',
        ),
      ]);

      // Ecrire « le bus va au marche » puis creer le marche est une facon
      // normale d'avancer. Une promesse pas encore tenue et une faute de frappe
      // sont indiscernables : les traiter en faute interdirait d'ecrire le
      // parcours dans l'ordre ou il se raconte.
      expect(issuesOf(adventure, IssueSeverity.wrong), isEmpty);
      final incomplete = issuesOf(adventure, IssueSeverity.incomplete);
      expect(incomplete, hasLength(1));
      expect(incomplete.single.message, contains('marche'));
      expect(incomplete.single.familyId, 'en_bus');
    });

    test('une etape qu\'aucun chemin n\'atteint', () {
      final adventure = adventureOf(<Stage>[
        stage(
          id: 'depart',
          families: <WordFamily>[
            family(
              id: 'en_bus',
              label: 'En autocar',
              words: <Word>[word('ticket')],
              destination: 'depart',
            ),
          ],
        ),
        stage(
          id: 'orpheline',
          families: <WordFamily>[
            family(
              id: 'ailleurs',
              label: 'Ailleurs',
              words: <Word>[word('sentier')],
              destination: 'depart',
            ),
          ],
        ),
      ]);

      // Un lieu ecrit avant d'etre relie : normal en cours de route.
      expect(issuesOf(adventure, IssueSeverity.wrong), isEmpty);
      final incomplete = issuesOf(adventure, IssueSeverity.incomplete);
      expect(incomplete, hasLength(1));
      expect(incomplete.single.stageId, 'orpheline');
    });
  });

  group('Ce que l\'outil doit pouvoir dire', () {
    test('une aventure jouable ne presente aucune anomalie', () {
      final adventure = adventureWith(<WordFamily>[
        family(
          id: 'en_bus',
          label: 'En autocar',
          words: <Word>[word('ticket', const <String>['ti', 'ket'])],
          destination: 'depart',
        ),
      ]);

      expect(adventure.validate(), isEmpty);
    });

    test('chaque anomalie designe le lieu ou la corriger', () {
      final adventure = adventureWith(<WordFamily>[
        family(
          id: 'en_bus',
          label: 'En bus',
          words: <Word>[word('bus'), word('ticket', const <String>[])],
        ),
      ]);

      // Sans cela l'outil ne saurait pas sur quel lieu poser le signalement.
      expect(adventure.validate(), isNotEmpty);
      for (final issue in adventure.validate()) {
        expect(
          issue.stageId,
          isNotNull,
          reason: 'Anomalie sans lieu : « ${issue.message} »',
        );
      }
    });
  });
}
