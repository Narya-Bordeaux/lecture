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
    test('deux listes qui ne disent plus que la meme chose', () {
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
          destination: 'depart',
        ),
      ]);

      final wrong = issuesOf(adventure, IssueSeverity.wrong);

      // Le mot partage n'est plus une faute : il est retire des deux cotes
      // avant le tirage, et ne peut donc plus arriver a l'ecran. Ce qui est
      // faux, c'est ce qu'il laisse — les deux listes se vident entierement,
      // et continuer d'ecrire n'y changera rien tant qu'elles se recouvrent.
      expect(wrong, hasLength(2));
      expect(
        wrong.map((issue) => issue.familyId),
        containsAll(<String>['en_bus', 'a_pied']),
      );
      expect(wrong.first.stageId, 'depart');
    });

    test('un reste entierement pris par le theme', () {
      // Tri unique : le reste perd les mots du theme, le theme ne perd rien.
      // Un reste qui ne contient que des mots du theme n'a plus rien a
      // proposer — seul lui est en faute.
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
      expect(wrong.map((issue) => issue.familyId), <String?>['a_pied']);
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

  group('Une fin se declare', () {
    // Une etape sans famille clot le parcours. Mais une etape qu'on vient de
    // creer et qu'on n'a pas encore ecrite n'a pas de famille non plus : sans
    // marqueur, les deux sont indiscernables et un lieu oublie passe pour une
    // fin. D'ou `isEnding`, declare.
    //
    // La contrepartie de cette redondance est qu'elle doit etre **verifiable** :
    // le marqueur et la structure ne doivent jamais se contredire, sans quoi
    // l'information en double finirait par diverger.

    test('une fin declaree et sans famille ne pose aucun probleme', () {
      final adventure = adventureOf(<Stage>[
        stage(
          id: 'depart',
          families: <WordFamily>[
            family(
              id: 'en_bus',
              label: 'En autocar',
              words: <Word>[word('ticket', const <String>['ti', 'ket'])],
              destination: 'plage',
            ),
          ],
        ),
        ending(id: 'plage', location: 'La plage'),
      ]);

      expect(adventure.validate(), isEmpty);
    });

    test('un lieu cree et pas encore ecrit est signale incomplet', () {
      final adventure = adventureOf(<Stage>[
        stage(
          id: 'depart',
          families: <WordFamily>[
            family(
              id: 'en_bus',
              label: 'En autocar',
              words: <Word>[word('ticket', const <String>['ti', 'ket'])],
              destination: 'marche',
            ),
          ],
        ),
        // Ni famille, ni marqueur de fin : l'auteur l'a pose et abandonne.
        stage(id: 'marche', families: const <WordFamily>[]),
      ]);

      expect(issuesOf(adventure, IssueSeverity.wrong), isEmpty);
      final incomplete = issuesOf(adventure, IssueSeverity.incomplete);
      expect(incomplete, hasLength(1));
      expect(incomplete.single.stageId, 'marche');
    });

    test('une fin qui porte des familles se contredit', () {
      final adventure = adventureOf(<Stage>[
        Stage(
          id: 'depart',
          locationName: 'Depart',
          isEnding: true,
          families: <WordFamily>[
            family(
              id: 'en_bus',
              label: 'En autocar',
              words: <Word>[word('ticket', const <String>['ti', 'ket'])],
              destination: 'depart',
            ),
          ],
        ),
      ]);

      // C'est tout l'interet d'avoir rendu la redondance verifiable : le
      // marqueur et la structure ne peuvent plus diverger en silence.
      final wrong = issuesOf(adventure, IssueSeverity.wrong);
      expect(wrong, hasLength(1));
      expect(wrong.single.stageId, 'depart');
    });
  });

  group('Le tri unique', () {
    // Une autre mecanique de lecture : au lieu de trier entre plusieurs
    // familles homogenes, l'enfant trie entre **une liste et son complement**
    // — ce qui est du theme, et tout le reste. Rien a comparer d'un mot a
    // l'autre : chacun se juge seul contre un seul critere.
    //
    // La structure le dit : une famille sans destination est la liste du
    // reste. Rien a declarer en plus.

    test('une liste du reste fait du lieu un tri unique', () {
      final sorting = stage(
        id: 'boutique',
        families: <WordFamily>[
          family(
            id: 'a_manger',
            label: 'Ce qui se mange',
            words: <Word>[word('pain', const <String>['pain'])],
            destination: 'depart',
          ),
          family(id: 'le_reste', label: 'Le reste', words: <Word>[
            word('vélo', const <String>['vé', 'lo']),
          ]),
        ],
      );

      expect(sorting.isSingleSort, isTrue);
    });

    test('un tri entre plusieurs familles n\'en est pas un', () {
      final ordinary = stage(
        id: 'depart',
        families: <WordFamily>[
          family(
            id: 'en_bus',
            label: 'En autocar',
            words: <Word>[word('ticket', const <String>['ti', 'ket'])],
            destination: 'depart',
          ),
        ],
      );

      expect(ordinary.isSingleSort, isFalse);
    });

    test('un tri unique qui aurait deux sorties se contredit', () {
      final adventure = adventureOf(<Stage>[
        stage(
          id: 'depart',
          families: <WordFamily>[
            family(
              id: 'a_manger',
              label: 'Ce qui se mange',
              words: <Word>[word('pain', const <String>['pain'])],
              destination: 'depart',
            ),
            family(
              id: 'a_boire',
              label: 'Ce qui se boit',
              words: <Word>[word('eau', const <String>['eau'])],
              destination: 'depart',
            ),
            family(id: 'le_reste', label: 'Le reste', words: <Word>[
              word('vélo', const <String>['vé', 'lo']),
            ]),
          ],
        ),
      ]);

      // Le tri unique tient a ce qu'il n'y ait qu'un seul choix. Deux sorties
      // en feraient un tri ordinaire affuble d'une liste de rebut.
      final wrong = issuesOf(adventure, IssueSeverity.wrong);
      expect(wrong, hasLength(1));
      expect(wrong.single.stageId, 'depart');
    });

    test('la boutique du contenu livre en est un, et reste valide', () {
      // Elle a « ce qui se mange » d'un cote, « laisse-le » de l'autre.
      final sorting = stage(
        id: 'boutique',
        families: <WordFamily>[
          family(
            id: 'a_manger',
            label: 'Ce qui se mange',
            words: <Word>[word('pain', const <String>['pain'])],
            destination: 'depart',
          ),
          family(id: 'a_laisser', label: 'Laisse-le', words: <Word>[
            word('vélo', const <String>['vé', 'lo']),
          ]),
        ],
      );
      final adventure = adventureOf(<Stage>[sorting], start: 'boutique');

      expect(sorting.isSingleSort, isTrue);
      expect(issuesOf(adventure, IssueSeverity.wrong), isEmpty);
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
