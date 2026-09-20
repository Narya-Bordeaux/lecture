import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_game/application/stage_engine.dart';
import 'package:reading_game/domain/models/adventure.dart';

/// Lit le contenu depuis le disque plutot que depuis le bundle : ce test porte
/// sur les donnees pedagogiques elles-memes, pas sur leur chargement par
/// Flutter.
Adventure loadAdventureFromDisk(String adventureId) {
  final file = File('assets/content/adventures/$adventureId.json');
  expect(file.existsSync(), isTrue, reason: 'Fichier absent : ${file.path}');
  return Adventure.fromJson(
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
  );
}

void main() {
  group('Contenu de l\'aventure « Grisbie va à la plage »', () {
    late Adventure adventure;

    setUp(() => adventure = loadAdventureFromDisk('grisbie_beach'));

    test('le contenu ne presente aucune incoherence', () {
      // Couvre notamment les mots ambigus, que la specification proscrit, et
      // les destinations pointant vers une etape inexistante.
      expect(adventure.validate(), isEmpty);
    });

    test('l\'etape de depart propose trois chemins', () {
      final start = adventure.startStage;

      expect(start.id, 'home');
      expect(start.families, hasLength(3));
      expect(start.words, hasLength(6));
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
          for (final wordId in family.wordIds) {
            final word = stage.findWord(wordId)!;
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
      final station = adventure.findStage('station_hall');

      expect(station, isNotNull);
      expect(station!.isTerminal, isFalse);
      expect(station.families, hasLength(2));
    });

    test('la plage est une etape terminale', () {
      expect(adventure.findStage('beach')!.isTerminal, isTrue);
    });

    test('chaque mot possede un decoupage syllabique', () {
      for (final stage in adventure.stages.values) {
        for (final word in stage.words) {
          expect(
            word.syllables,
            isNotEmpty,
            reason: 'Mot sans syllabes : ${word.id}',
          );
          expect(
            word.syllables.join(),
            equalsIgnoringCase(word.text.replaceAll('-', '')),
            reason: 'Les syllabes de "${word.text}" ne le reconstituent pas',
          );
        }
      }
    });
  });

  group('Parcours complet jusqu\'a la plage', () {
    test('classer puis partir mene de la maison a la mer', () {
      final adventure = loadAdventureFromDisk('grisbie_beach');

      // Premiere etape : choisir le bus.
      final home = StageEngine(stage: adventure.startStage, random: Random(1));
      home.placeWord(wordId: 'bus_stop', familyId: 'by_bus');
      home.placeWord(wordId: 'ticket', familyId: 'by_bus');

      expect(home.state.availableDestinations, hasLength(1));
      home.departTo('station_hall');

      // Seconde etape : l'etape imbriquee, dans la gare.
      final station = StageEngine(
        stage: adventure.findStage(home.state.departedTo!)!,
        random: Random(1),
      );
      station.placeWord(wordId: 'platform', familyId: 'take_the_train');
      station.placeWord(wordId: 'rail_ticket', familyId: 'take_the_train');
      station.departTo('beach');

      final beach = adventure.findStage(station.state.departedTo!)!;
      expect(beach.locationName, 'La plage');
      expect(beach.isTerminal, isTrue);
    });

    test('une famille non choisie mene ailleurs, sans bloquer', () {
      final adventure = loadAdventureFromDisk('grisbie_beach');
      final home = StageEngine(stage: adventure.startStage, random: Random(1));

      // L'enfant remplit deux familles avant de se decider.
      home.placeWord(wordId: 'shoe', familyId: 'on_foot');
      home.placeWord(wordId: 'path', familyId: 'on_foot');
      home.placeWord(wordId: 'bus_stop', familyId: 'by_bus');
      home.placeWord(wordId: 'ticket', familyId: 'by_bus');

      expect(home.state.availableDestinations, hasLength(2));
      expect(home.state.isFinished, isFalse);

      home.departTo('street');
      expect(home.state.departedTo, 'street');
    });
  });
}
