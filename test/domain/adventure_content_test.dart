import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/stage_engine.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/word.dart';

import '../support/disk_content.dart';

void main() {
  group('Contenu de l\'aventure « Grisbie va à la plage »', () {
    late Adventure adventure;

    setUp(() async => adventure = await loadRealAdventure());

    test('le contenu ne presente aucune incoherence', () {
      // Couvre notamment les mots ambigus, que la specification proscrit, et
      // les destinations pointant vers une etape inexistante.
      expect(adventure.validate(), isEmpty);
    });

    test('l\'etape de depart propose trois chemins', () {
      final start = adventure.startStage;

      expect(start.id, 'maison');
      expect(start.families, hasLength(3));
    });

    test('les listes peuvent etre de tailles differentes', () {
      // Les familles n'ont pas le meme champ lexical disponible : « En
      // voiture » partage presque tout son vocabulaire avec « En bus », donc
      // sa liste est plus courte. Rien n'impose de les egaliser.
      final sizes = adventure.startStage.families
          .map((family) => family.wordTexts.length)
          .toSet();

      expect(sizes, isNotEmpty);
      for (final family in adventure.startStage.families) {
        expect(
          family.wordTexts.length,
          greaterThanOrEqualTo(family.requiredCount),
          reason:
              'La famille "${family.id}" demande plus de mots qu\'elle n\'en a',
        );
      }
    });

    test('six mots sont proposes a la fois, les autres attendent', () {
      final start = adventure.startStage;
      final engine = StageEngine(stage: start, random: Random(1));

      expect(start.visibleWordCount, 6);
      expect(engine.visibleWords.whereType<Word>(), hasLength(6));
      expect(
        engine.state.remainingInSupply,
        start.words.length - start.visibleWordCount,
      );
    });

    test('une famille s\'ouvre quand toute sa liste est classee', () {
      // Les listes sont pleines, sans objectif raccourci : remplir entierement
      // une categorie est en soi une aide, puisque les mots restants ne
      // peuvent plus lui appartenir et que le choix se reduit.
      for (final family in adventure.startStage.families) {
        expect(
          family.goal,
          isNull,
          reason: 'La famille "${family.id}" raccourcit sa liste',
        );
        expect(family.requiredCount, family.wordTexts.length);
      }
    });

    test('l\'etape de depart pose ses trois zones sur l\'illustration', () {
      final start = adventure.startStage;

      expect(start.backgroundAsset, isNotNull);
      for (final family in start.families) {
        expect(
          family.area,
          isNotNull,
          reason: 'La famille "${family.id}" n\'a pas de zone posee',
        );
        expect(family.area!.overflows, isFalse);
      }
    });

    test('aucun mot ne se devine par le nom de sa famille', () {
      // Verifie explicitement le piege pedagogique : « bus » dans « En bus »
      // se classerait en comparant les lettres, sans comprendre le sens.
      for (final stage in adventure.stages.values) {
        for (final family in stage.families) {
          for (final wordText in family.wordTexts) {
            final word = stage.findWord(wordText)!;
            expect(
              family.label.toLowerCase().contains(word.text.toLowerCase()),
              isFalse,
              reason: '"${word.text}" apparait dans "${family.label}"',
            );
          }
        }
      }
    });

    test('la gare ouvre a son tour deux directions', () {
      final station = adventure.findStage('gare');

      expect(station, isNotNull);
      expect(station!.isTerminal, isFalse);
      expect(station.families, hasLength(2));
    });

    test('la plage est une etape terminale', () {
      expect(adventure.findStage('plage')!.isTerminal, isTrue);
    });

    test('chaque mot possede un decoupage', () {
      // Le decoupage suit les sons, pas les lettres : « arret » se coupe en
      // « a » et « rê ». Il n'a donc pas a reconstituer l'orthographe, et rien
      // ne le controle — seule son absence est une faute de contenu.
      for (final stage in adventure.stages.values) {
        for (final word in stage.words) {
          expect(
            word.syllables,
            isNotEmpty,
            reason: 'Mot sans decoupage : ${word.text}',
          );
        }
      }
    });
  });

  group('Parcours complet jusqu\'a la plage', () {
    test('classer puis partir mene de la maison a la mer', () async {
      final adventure = await loadRealAdventure();

      // Premiere etape : classer assez de mots « bus » pour ouvrir la gare.
      final home = StageEngine(stage: adventure.startStage, random: Random(1));
      final busFamily = adventure.startStage.families.firstWhere(
        (family) => family.id == 'en_bus',
      );
      for (final wordText in busFamily.wordTexts.take(busFamily.requiredCount)) {
        home.placeWord(wordText: wordText, familyId: 'en_bus');
      }

      expect(home.state.availableDestinations, hasLength(1));
      home.departTo('gare');

      // Seconde etape : l'etape imbriquee, dans la gare.
      final station = StageEngine(
        stage: adventure.findStage(home.state.departedTo!)!,
        random: Random(1),
      );
      station.placeWord(wordText: 'quai', familyId: 'prendre_le_train');
      station.placeWord(wordText: 'billet', familyId: 'prendre_le_train');
      station.departTo('plage');

      final beach = adventure.findStage(station.state.departedTo!)!;
      expect(beach.locationName, 'La plage');
      expect(beach.isTerminal, isTrue);
    });

    test('une famille non choisie mene ailleurs, sans bloquer', () async {
      final adventure = await loadRealAdventure();
      final home = StageEngine(stage: adventure.startStage, random: Random(1));

      // L'enfant ouvre deux chemins avant de se decider.
      for (final familyId in <String>['a_pied', 'en_bus']) {
        final family = adventure.startStage.families.firstWhere(
          (family) => family.id == familyId,
        );
        for (final wordText in family.wordTexts.take(family.requiredCount)) {
          home.placeWord(wordText: wordText, familyId: familyId);
        }
      }

      expect(home.state.availableDestinations, hasLength(2));
      expect(home.state.isFinished, isFalse);

      home.departTo('rue');
      expect(home.state.departedTo, 'rue');
    });
  });
}
