import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/adventure_outline.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/narrative.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';

import '../support/disk_content.dart';
import '../support/stage_builders.dart';

/// Le lettrage positionnel d'une aventure, tel qu'il s'affiche a l'auteur.
///
/// La regle vient du croquis papier de l'auteur, et elle n'est pas celle qu'on
/// devine : `B1` donne `C1, C2` tandis que `B2` donne `D1, D2`. La lettre ne
/// marque donc **pas la profondeur** — chaque point qui se deploie consomme la
/// lettre suivante pour le groupe de ses arrivees.
///
/// Ce lettrage ne se stocke jamais : il se recalcule. Il bouge d'ailleurs des
/// qu'on insere un trajet, ce qui en ferait un tres mauvais identifiant.

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

/// Un trajet nomme, menant quelque part.
WordFamily trip(String id, String label, {String? to}) {
  return family(
    id: id,
    label: label,
    words: <Word>[word('$id-mot', const <String>['a'])],
    destination: to,
  );
}

void main() {
  group('Le lettrage suit le croquis', () {
    late AdventureOutline outline;

    setUpAll(() {
      // Exactement l'arbre de la photo : A donne B1 B2 B3 ; B1 donne C1 C2 ;
      // B2 donne D1 D2 ; B3 donne E1 E2 ; C1 donne F1.
      outline = AdventureOutline.of(adventureOf(<Stage>[
        stage(id: 'depart', families: <WordFamily>[
          trip('en_bus', 'En bus', to: 'arret'),
          trip('en_voiture', 'En voiture', to: 'garage'),
          trip('a_pied', 'A pied', to: 'sentier'),
        ]),
        stage(id: 'arret', families: <WordFamily>[
          trip('gare', 'La gare', to: 'gare'),
          trip('marche', 'Le marche', to: 'marche'),
        ]),
        stage(id: 'garage', families: <WordFamily>[
          trip('pompe', 'La pompe', to: 'pompe'),
          trip('atelier', 'L\'atelier', to: 'atelier'),
        ]),
        stage(id: 'sentier', families: <WordFamily>[
          trip('foret', 'La foret', to: 'foret'),
          trip('pont', 'Le pont', to: 'pont'),
        ]),
        stage(id: 'gare', families: <WordFamily>[
          trip('guichet', 'Le guichetier', to: 'guichet'),
        ]),
        ending(id: 'marche'),
        ending(id: 'pompe'),
        ending(id: 'atelier'),
        ending(id: 'foret'),
        ending(id: 'pont'),
        ending(id: 'guichet'),
      ]));
    });

    test('le depart porte une lettre seule', () {
      expect(outline.letterOf('depart'), 'A');
    });

    test('les arrivees du depart forment le groupe B', () {
      expect(outline.letterOf('arret'), 'B1');
      expect(outline.letterOf('garage'), 'B2');
      expect(outline.letterOf('sentier'), 'B3');
    });

    test('chaque point qui se deploie prend la lettre suivante', () {
      // C'est le point qui ne se devine pas : B2 ne donne pas « C3 ».
      expect(outline.letterOf('gare'), 'C1');
      expect(outline.letterOf('marche'), 'C2');
      expect(outline.letterOf('pompe'), 'D1');
      expect(outline.letterOf('atelier'), 'D2');
      expect(outline.letterOf('foret'), 'E1');
      expect(outline.letterOf('pont'), 'E2');
      expect(outline.letterOf('guichet'), 'F1');
    });

    test('les blocs se lisent dans l\'ordre du croquis', () {
      expect(
        outline.blocks.map((block) => block.letter).toList(),
        <String>['A', 'B1', 'B2', 'B3', 'C1'],
      );
    });

    test('un bloc porte ses trajets nommes, dans l\'ordre', () {
      final start = outline.blocks.first;

      expect(start.stageId, 'depart');
      expect(
        start.trips.map((trip) => trip.label).toList(),
        <String>['En bus', 'En voiture', 'A pied'],
      );
      expect(
        start.trips.map((trip) => trip.destinationLetter).toList(),
        <String?>['B1', 'B2', 'B3'],
      );
    });

    test('une fin ne se deploie pas', () {
      expect(
        outline.blocks.any((block) => block.stageId == 'marche'),
        isFalse,
      );
    });
  });

  group('Ce que le lettrage doit encaisser', () {
    test('un lieu atteint par deux chemins ne porte qu\'une lettre', () {
      final outline = AdventureOutline.of(adventureOf(<Stage>[
        stage(id: 'depart', families: <WordFamily>[
          trip('en_bus', 'En bus', to: 'gare'),
          trip('a_pied', 'A pied', to: 'gare'),
        ]),
        ending(id: 'gare'),
      ]));

      expect(outline.letterOf('gare'), 'B1');
      // Le second trajet pointe la meme lettre, il n'en invente pas une autre.
      expect(
        outline.blocks.first.trips.map((trip) => trip.destinationLetter),
        <String?>['B1', 'B1'],
      );
    });

    test('un trajet vers un lieu pas encore cree n\'a pas de lettre', () {
      final outline = AdventureOutline.of(adventureOf(<Stage>[
        stage(id: 'depart', families: <WordFamily>[
          trip('en_bus', 'En bus', to: 'marche'),
        ]),
      ]));

      final only = outline.blocks.first.trips.single;
      expect(only.destinationStageId, 'marche');
      expect(only.destinationLetter, isNull);
    });

    test('un classeur sans issue apparait, sans arrivee', () {
      // La famille de rebut d'une rencontre : « garde-le ». Elle existe, il
      // faut la voir, mais elle n'ouvre aucun chemin.
      final outline = AdventureOutline.of(adventureOf(<Stage>[
        stage(id: 'depart', families: <WordFamily>[
          trip('a_manger', 'A manger', to: 'plage'),
          trip('a_laisser', 'Laisse-le'),
        ]),
        ending(id: 'plage'),
      ]));

      final trips = outline.blocks.first.trips;
      expect(trips, hasLength(2));
      expect(trips.last.destinationStageId, isNull);
      expect(trips.last.destinationLetter, isNull);
    });

    test('un lieu qu\'aucun chemin n\'atteint apparait quand meme', () {
      // Sinon un lieu cree puis oublie disparaitrait de l'ecran, et l'auteur
      // ne pourrait plus le relier.
      final outline = AdventureOutline.of(adventureOf(<Stage>[
        stage(id: 'depart', families: <WordFamily>[
          trip('en_bus', 'En bus', to: 'plage'),
        ]),
        ending(id: 'plage'),
        stage(id: 'orpheline', families: <WordFamily>[
          trip('ailleurs', 'Ailleurs', to: 'plage'),
        ]),
      ]));

      expect(outline.letterOf('orpheline'), isNotNull);
      expect(outline.detachedStageIds, <String>['orpheline']);
    });

    test('un cycle ne fait pas tourner le rendu sans fin', () {
      final outline = AdventureOutline.of(adventureOf(<Stage>[
        stage(id: 'depart', families: <WordFamily>[
          trip('aller', 'Aller', to: 'retour'),
        ]),
        stage(id: 'retour', families: <WordFamily>[
          trip('revenir', 'Revenir', to: 'depart'),
        ]),
      ]));

      expect(outline.letterOf('depart'), 'A');
      expect(outline.letterOf('retour'), 'B1');
      expect(outline.blocks, hasLength(2));
    });

    test('au-dela de vingt-six groupes, les lettres se doublent', () {
      // Un parcours tres ramifie ne doit pas produire deux groupes homonymes.
      final stages = <Stage>[
        stage(
          id: 'depart',
          families: <WordFamily>[
            for (var i = 0; i < 30; i++) trip('t$i', 'Trajet $i', to: 'e$i'),
          ],
        ),
        for (var i = 0; i < 30; i++)
          stage(id: 'e$i', families: <WordFamily>[
            trip('s$i', 'Suite $i', to: 'f$i'),
          ]),
        for (var i = 0; i < 30; i++) ending(id: 'f$i'),
      ];

      final outline = AdventureOutline.of(adventureOf(stages));
      final groups = <String>{
        for (var i = 0; i < 30; i++) outline.letterOf('f$i')!,
      };

      expect(groups, hasLength(30), reason: 'Deux groupes portent la meme '
          'lettre : deux lieux deviendraient indiscernables a l\'ecran.');
    });
  });

  group('Sur l\'aventure reelle', () {
    test('le lettrage decrit le parcours livre', () async {
      final outline = AdventureOutline.of(await loadRealAdventure());

      expect(outline.letterOf('maison'), 'A');
      // Trois directions au depart, dont la gare.
      expect(outline.blocks.first.trips, hasLength(3));
      expect(outline.detachedStageIds, isEmpty);

      // Chaque lieu du contenu porte une lettre : aucun ne disparait.
      final lettered = outline.blocks.map((block) => block.stageId).toSet();
      expect(lettered, contains('maison'));
      expect(lettered, contains('gare'));
    });

    test('le texte de transition est reporte, comme la case du croquis',
        () async {
      final outline = AdventureOutline.of(await loadRealAdventure());
      final start = outline.blocks.first;

      // « maison » a un onCompletion : la case est cochee sur ses trajets.
      expect(start.hasTransitionText, isTrue);
    });

    test('un lieu sans recit de depart laisse la case vide', () {
      final outline = AdventureOutline.of(adventureOf(<Stage>[
        Stage(
          id: 'depart',
          locationName: 'Depart',
          narrative: Narrative.none,
          families: <WordFamily>[trip('en_bus', 'En bus', to: 'plage')],
        ),
        ending(id: 'plage'),
      ]));

      expect(outline.blocks.first.hasTransitionText, isFalse);
    });
  });
}
