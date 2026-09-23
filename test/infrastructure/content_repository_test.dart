import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/infrastructure/content/content_repository.dart';

import '../support/disk_content.dart';
import '../support/memory_content.dart';

/// Un contenu minimal mais valide, que chaque test deforme a sa guise.
Map<String, String> buildFiles({
  String? lexiconWords,
  String? familyWords,
  String? characters,
  String? encounter,
}) {
  return <String, String>{
    'index.json': '''
{
  "lexicons": ["lexicon/test.json"],
  "lists": ["lists/test.json"],
  "characters": "characters.json",
  "adventures": [
    { "id": "test", "title": "Essai", "file": "adventures/test.json" }
  ]
}''',
    'lexicon/test.json': '''
{ "domain": "test", "words": [
  ${lexiconWords ?? '''
  { "text": "un", "syllables": ["un"] },
  { "text": "deux", "syllables": ["deux"] }'''}
] }''',
    'lists/test.json': '''
{ "domain": "test", "lists": [
  { "id": "liste_une", "name": "La liste",
    "words": [${familyWords ?? '"un", "deux"'}] }
] }''',
    'characters.json': characters ??
        '{ "characters": [ { "id": "guide", "name": "Le guide" } ] }',
    'adventures/test.json': '''
{
  "id": "test",
  "title": "Essai",
  "startStageId": "start",
  "stages": [
    {
      "id": "start",
      "location": "Depart",
      "narrative": { "onArrival": "Bonjour." },
      ${encounter ?? ''}
      "families": [
        { "id": "one", "label": "Famille", "list": "liste_une",
          "destination": "end" }
      ]
    },
    { "id": "end", "location": "Arrivee", "families": [], "ending": true }
  ]
}''',
  };
}

ContentRepository buildRepository(Map<String, String> files) {
  return ContentRepository(source: MemoryContentFolder(files));
}

void main() {
  group('Fichier pere', () {
    test('annonce les aventures sans les charger', () async {
      final index = await buildRepository(buildFiles()).loadIndex();

      expect(index.adventures, hasLength(1));
      expect(index.adventures.first.title, 'Essai');
      expect(index.lexiconFiles, <String>['lexicon/test.json']);
      expect(index.wordListFiles, <String>['lists/test.json']);
    });

    test('une aventure non declaree est refusee en la nommant', () async {
      expect(
        () => buildRepository(buildFiles()).loadAdventure('inconnue'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('inconnue'),
          ),
        ),
      );
    });
  });

  group('Resolution des references', () {
    test('les mots viennent du lexique, pas de l\'aventure', () async {
      final adventure = await buildRepository(buildFiles()).loadAdventure(
        'test',
      );

      // L'aventure ne porte que le mot ; le lexique dit qu'il existe.
      final word = adventure.startStage.findWord('un');
      expect(word, isNotNull);
      expect(word!.text, 'un');
    });

    test('un mot inconnu est signale en le nommant', () async {
      final files = buildFiles(familyWords: '"un", "fantome"');

      expect(
        () => buildRepository(files).loadAdventure('test'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('fantome'),
          ),
        ),
      );
    });

    test('un mot defini deux fois dans le lexique est refuse', () async {
      // Le mot etant sa propre clef, deux entrees de meme orthographe se
      // contredisent : rien ne dirait lequel des deux decoupages s'applique.
      final files = buildFiles(
        lexiconWords: '''
        { "text": "un", "syllables": ["un"] },
        { "text": "un", "syllables": ["u", "n"] },
        { "text": "deux", "syllables": ["deux"] }''',
      );

      expect(
        () => buildRepository(files).loadAdventure('test'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('un'),
          ),
        ),
      );
    });

    test('un personnage inconnu est signale par son identifiant', () async {
      final files = buildFiles(
        encounter: '"character": { "id": "absent", "line": "Bonjour !" },',
      );

      expect(
        () => buildRepository(files).loadAdventure('test'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('absent'),
          ),
        ),
      );
    });
  });

  group('Structure d\'une etape', () {
    test('le recit a deux temps', () async {
      final adventure = await buildRepository(buildFiles()).loadAdventure(
        'test',
      );

      expect(adventure.startStage.narrative.onArrival, 'Bonjour.');
    });

    test('un personnage fait de l\'etape une rencontre', () async {
      final files = buildFiles(
        encounter: '"character": { "id": "guide", "line": "Suis-moi !" },',
      );

      final adventure = await buildRepository(files).loadAdventure('test');
      final stage = adventure.startStage;

      expect(stage.isEncounter, isTrue);
      expect(stage.encounter!.character.name, 'Le guide');
      expect(stage.encounter!.line, 'Suis-moi !');
    });

    test('sans personnage, l\'etape est un simple classement', () async {
      final adventure = await buildRepository(buildFiles()).loadAdventure(
        'test',
      );

      expect(adventure.startStage.isEncounter, isFalse);
    });

    test('les mots de l\'etape sont ceux de ses familles', () async {
      final adventure = await buildRepository(buildFiles()).loadAdventure(
        'test',
      );

      expect(
        adventure.startStage.words.map((word) => word.text),
        <String>['un', 'deux'],
      );
    });
  });

  group('Page de garde', () {
    test('une aventure peut s\'ouvrir sur un titre, une image et un texte',
        () async {
      final files = buildFiles();
      files['adventures/test.json'] = files['adventures/test.json']!.replaceFirst(
        '"startStageId": "start",',
        '"startStageId": "start",'
        '"opening": { "title": "Le grand depart", '
        '"image": "assets/pictures/cover.jpg", "text": "Il etait une fois." },',
      );

      final adventure = await buildRepository(files).loadAdventure('test');

      expect(adventure.opening, isNotNull);
      expect(adventure.opening!.titleOr(adventure.title), 'Le grand depart');
      expect(adventure.opening!.imageAsset, 'assets/pictures/cover.jpg');
      expect(adventure.opening!.text, 'Il etait une fois.');
    });

    test('sans titre propre, celui de l\'aventure prend sa place', () async {
      final files = buildFiles();
      files['adventures/test.json'] = files['adventures/test.json']!.replaceFirst(
        '"startStageId": "start",',
        '"startStageId": "start","opening": { "text": "Bonjour." },',
      );

      final adventure = await buildRepository(files).loadAdventure('test');

      expect(adventure.opening!.titleOr(adventure.title), 'Essai');
    });

    test('une aventure sans page de garde reste valide', () async {
      final adventure = await buildRepository(buildFiles()).loadAdventure(
        'test',
      );

      expect(adventure.opening, isNull);
    });
  });

  group('Contenu livre', () {
    test('l\'aventure de Grisbie se charge et se valide', () async {
      final adventure = await loadRealAdventure();

      expect(adventure.id, 'grisbie_plage');
      expect(adventure.validate(), isEmpty);
    });

    test('l\'aventure s\'ouvre sur sa page de garde', () async {
      final adventure = await loadRealAdventure();
      final opening = adventure.opening;

      expect(opening, isNotNull);
      expect(opening!.titleOr(adventure.title), 'Grisbie part à la plage');
      expect(opening.imageAsset, 'pictures/Grisbie_plage.jpg');
      expect(opening.text, isNotEmpty);
    });

    test('la rencontre de la boutique pose son enigme', () async {
      final adventure = await loadRealAdventure();
      final shop = adventure.findStage('boutique')!;

      expect(shop.isEncounter, isTrue);
      expect(shop.encounter!.character.name, 'La marchande de journaux');

      // Le classeur de rebut ne mene nulle part : le remplir n'ouvre rien.
      final keep = shop.findFamily('a_laisser')!;
      expect(keep.leadsSomewhere, isFalse);
      expect(shop.findFamily('a_manger')!.leadsSomewhere, isTrue);
    });
  });

  group('La bibliotheque de l\'outil', () {
    test('elle rend toutes les listes', () async {
      // Pour reutiliser une liste plutot que de la reecrire.
      final library = await buildRepository(buildFiles()).loadLibrary();

      expect(library.lists.contains('liste_une'), isTrue);
    });

    test('elle se lit sans ouvrir d\'aventure', () async {
      final repository = buildRepository(buildFiles());
      final library = await repository.loadLibrary();
      final adventure = await repository.loadDraft('test');

      // Le meme catalogue sert aux deux : une seule lecture.
      expect(
        adventure.startStage.families.single.list.id,
        library.lists.resolve('liste_une').id,
      );
    });
  });
}
