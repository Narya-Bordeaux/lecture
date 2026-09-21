import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/adventure_opening.dart';
import 'package:grisbie/domain/models/narrative.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word_family.dart';

import '../support/stage_builders.dart';

/// Reprendre une aventure deja ecrite, lieu par lieu.
///
/// L'outil d'auteur travaille en memoire et rend l'aventure modifiee. Il lui
/// faut donc de quoi remplacer un lieu sans reconstruire l'aventure a la main —
/// ce qui, a chaque champ ajoute, en perdrait un en silence.

Adventure twoStages() {
  return Adventure(
    id: 'essai',
    title: 'Essai',
    startStageId: 'maison',
    stages: <String, Stage>{
      'maison': stage(
        id: 'maison',
        families: const <WordFamily>[],
        location: 'Devant la maison',
      ),
      'plage': ending(id: 'plage', location: 'La plage'),
    },
  );
}

void main() {
  group('Remplacer un lieu', () {
    test('le lieu modifie prend la place de l\'ancien', () {
      final edited = twoStages().withStage(
        stage(
          id: 'maison',
          families: const <WordFamily>[],
          location: 'Devant la grande maison',
        ),
      );

      expect(edited.findStage('maison')!.locationName, 'Devant la grande maison');
      expect(edited.stages, hasLength(2));
    });

    test('le reste de l\'aventure ne bouge pas', () {
      final before = twoStages();
      final edited = before.withStage(
        before.startStage.copyWith(locationName: 'Ailleurs'),
      );

      expect(edited.id, before.id);
      expect(edited.title, before.title);
      expect(edited.startStageId, before.startStageId);
      expect(edited.findStage('plage')!.locationName, 'La plage');
    });

    test('un lieu inconnu est refuse en le nommant', () {
      // Un identifiant mal repris ajouterait un lieu fantome au lieu d'en
      // corriger un : l'auteur ne verrait sa faute que bien plus tard.
      expect(
        () => twoStages().withStage(ending(id: 'montagne')),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('montagne'),
          ),
        ),
      );
    });
  });

  group('L\'illustration s\'enleve aussi', () {
    test('copyWith la remplace', () {
      final illustrated = stage(id: 'maison', families: const <WordFamily>[])
          .copyWith(backgroundAsset: 'assets/pictures/a.jpg');

      expect(illustrated.backgroundAsset, 'assets/pictures/a.jpg');
    });

    test('et sait la retirer, ce que « ?? » ne ferait jamais', () {
      // `copyWith` garde l'ancienne valeur quand on ne passe rien : sans un
      // geste explicite, retirer une illustration serait sans effet, et
      // l'auteur croirait l'avoir fait.
      final cleared = stage(id: 'maison', families: const <WordFamily>[])
          .copyWith(backgroundAsset: 'assets/pictures/a.jpg')
          .copyWith(clearBackgroundAsset: true);

      expect(cleared.backgroundAsset, isNull);
    });
  });

  group('La page de garde', () {
    test('s\'ajoute a une aventure qui n\'en a pas', () {
      final opened = twoStages().withOpening(
        const AdventureOpening(title: 'Grisbie part', text: 'Ce matin...'),
      );

      expect(opened.opening!.title, 'Grisbie part');
      expect(opened.opening!.text, 'Ce matin...');
    });

    test('se retire', () {
      final opened = twoStages()
          .withOpening(const AdventureOpening(text: 'Ce matin...'));

      expect(opened.withOpening(null).opening, isNull);
    });

    test('les lieux ne bougent pas au passage', () {
      final opened = twoStages()
          .withOpening(const AdventureOpening(text: 'Ce matin...'));

      expect(opened.stages, hasLength(2));
      expect(opened.startStage.locationName, 'Devant la maison');
    });
  });

  group('Le recit se reprend', () {
    test('un lieu raconte son arrivee, et elle seule', () {
      // Le depart ne se raconte pas : l'enfant clique un trajet, et c'est le
      // lieu d'arrivee qui raconte, avec son propre texte.
      final told = twoStages().startStage.copyWith(
            narrative: const Narrative(onArrival: 'Grisbie sort.'),
          );

      expect(told.narrative.onArrival, 'Grisbie sort.');
    });
  });
}
