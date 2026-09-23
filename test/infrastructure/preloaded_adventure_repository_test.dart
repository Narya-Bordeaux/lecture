import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word_family.dart';

import '../support/disk_content.dart';
import '../support/stage_builders.dart' as build;

/// Jouer l'aventure telle qu'elle est a l'ecran de l'outil, sans la relire.
///
/// L'essai porte sur ce que l'auteur voit, enregistre ou non : c'est ce qu'il
/// vient de regler qu'il veut eprouver sur l'appareil.
void main() {
  test('rend l\'aventure qu\'on lui a donnee', () async {
    final adventure = await loadRealAdventure();
    final repository = PreloadedAdventureRepository(adventure);

    expect(await repository.loadAdventure(adventure.id), same(adventure));
    expect(
      (await repository.loadIndex()).adventures.single.id,
      adventure.id,
    );
  });

  test('refuse une aventure injouable, comme le jeu', () async {
    // Le meme contrat que `ContentRepository.loadAdventure` : un essai qui
    // ouvrirait ce que le jeu refuse ne prouverait rien.
    final unfinished = Adventure(
      id: 'brouillon',
      title: 'Brouillon',
      startStageId: 'depart',
      stages: <String, Stage>{
        'depart': build.stage(id: 'depart', families: const <WordFamily>[]),
      },
    );

    expect(
      () => PreloadedAdventureRepository(unfinished).loadAdventure('brouillon'),
      throwsA(isA<FormatException>()),
    );
  });
}
