import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/infrastructure/content/content_repository.dart';
import 'package:grisbie/infrastructure/content/content_saver.dart';
import 'package:grisbie/infrastructure/content/content_writer.dart';

import '../support/memory_content.dart';

/// Enregistrer une aventure, entierement.
///
/// L'outil d'auteur travaillait en memoire et rendait l'aventure modifiee a
/// l'appelant ; personne ne l'ecrivait. Ecrire le seul fichier d'aventure ne
/// suffirait pas : il ne contient que des references. Sans son sommaire il est
/// introuvable, sans ses listes il cite des listes que personne n'a ecrites, et
/// sans le lexique ses listes citent des mots inconnus.
///
/// Le controle qui compte est donc le dernier de ce fichier : **le dossier
/// ecrit se recharge**. Tout le reste n'en est que le detail.

/// Un dossier de contenu livre, minimal mais complet.
MemoryContentFolder shippedFolder() {
  return MemoryContentFolder(<String, String>{
    'index.json': '''
{
  "lexicons": ["lexicon/transport.json"],
  "lists": ["lists/transport.json"],
  "characters": "characters.json",
  "adventures": [
    { "id": "plage", "title": "La plage", "file": "adventures/plage.json" }
  ]
}''',
    'lexicon/transport.json': '''
{ "domain": "transport", "words": [
  { "text": "quai", "syllables": ["quai"] },
  { "text": "billet", "syllables": ["bi", "llet"] }
] }''',
    'lists/transport.json': '''
{ "domain": "transport", "lists": [
  { "id": "train", "name": "Le train", "words": ["quai", "billet"] }
] }''',
    'characters.json': '{ "characters": [] }',
    'adventures/plage.json': '''
{
  "id": "plage",
  "title": "La plage",
  "startStageId": "gare",
  "stages": [
    {
      "id": "gare",
      "location": "La gare",
      "families": [
        { "id": "le_train", "label": "Prendre le train", "list": "train",
          "destination": "sable" }
      ]
    },
    { "id": "sable", "location": "Le sable", "families": [], "ending": true }
  ]
}''',
  });
}

/// Enregistre [adventure] et rend le dossier ecrit.
Future<MemoryContentFolder> saveInto(
  MemoryContentFolder shipped,
  Adventure adventure, {
  bool includeUnchanged = true,
}) async {
  final written = MemoryContentFolder();
  final folder = SplitContentFolder(source: shipped, written: written);

  await ContentSaver(
    source: folder,
    writer: ContentWriter(sink: folder),
  ).save(adventure, includeUnchanged: includeUnchanged);

  return written;
}

/// Le sommaire du dossier ecrit.
Future<Map<String, dynamic>> indexOf(MemoryContentFolder folder) async {
  return jsonDecode(await folder.readFile('index.json'))
      as Map<String, dynamic>;
}

void main() {
  late MemoryContentFolder shipped;
  late Adventure shippedAdventure;

  setUp(() async {
    shipped = shippedFolder();
    shippedAdventure =
        await ContentRepository(source: shipped).loadAdventure('plage');
  });

  group('Ce qu\'un enregistrement touche', () {
    test('l\'aventure, ses listes, le sommaire et le vocabulaire', () async {
      // Un trajet, donc une liste neuve : une aventure reduite a son point de
      // depart n'a aucune famille, et donc rien a ecrire dans `lists/`.
      final built = AdventureBuilder(
        AdventureBuilder.createAdventure(
          title: 'Grisbie au marché',
          startName: 'Devant la maison',
        ),
      ).addTrips('devant_la_maison', const <NewTrip>[NewTrip(name: 'En bus')]);

      final written = await saveInto(shipped, built);

      expect(
        written.files.keys,
        containsAll(<String>[
          'adventures/grisbie_au_marche.json',
          'lists/grisbie_au_marche.json',
          'index.json',
          'lexicon/transport.json',
          'characters.json',
          'lists/transport.json',
        ]),
      );
    });

    test('les autres aventures du sommaire sont recopiees', () async {
      // Sans elles, le dossier ecrit annoncerait des aventures introuvables, et
      // le defaut ne se verrait qu'en essayant d'en ouvrir une.
      final fresh = AdventureBuilder.createAdventure(
        title: 'Grisbie au marché',
        startName: 'Devant la maison',
      );

      final written = await saveInto(shipped, fresh);

      expect(
        written.files['adventures/plage.json'],
        shipped.files['adventures/plage.json'],
      );
    });

    test('le vocabulaire est recopie mot pour mot', () async {
      // L'outil ne cree pas de mots : le lexique passe tel quel, sans etre
      // relu ni reecrit par une serialisation qui pourrait en perdre.
      final written = await saveInto(shipped, shippedAdventure);

      expect(
        written.files['lexicon/transport.json'],
        shipped.files['lexicon/transport.json'],
      );
      expect(written.files['characters.json'], shipped.files['characters.json']);
    });
  });

  group('Le sommaire', () {
    test('declare l\'aventure enregistree', () async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Grisbie au marché',
        startName: 'Devant la maison',
      );

      final index = await indexOf(await saveInto(shipped, fresh));
      final adventures = (index['adventures'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      // Une aventure que le sommaire n'annonce pas est introuvable pour le jeu.
      expect(
        adventures.map((entry) => entry['id']),
        containsAll(<String>['plage', 'grisbie_au_marche']),
      );
    });

    test('ne declare pas deux fois la meme aventure', () async {
      // Enregistrer a nouveau est le geste le plus courant de tous.
      final index = await indexOf(await saveInto(shipped, shippedAdventure));
      final adventures = (index['adventures'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(adventures.where((entry) => entry['id'] == 'plage'), hasLength(1));
    });

    test('le titre modifie remplace l\'ancien', () async {
      final renamed = Adventure(
        id: shippedAdventure.id,
        title: 'La plage en hiver',
        startStageId: shippedAdventure.startStageId,
        stages: shippedAdventure.stages,
      );

      final index = await indexOf(await saveInto(shipped, renamed));
      final entry = (index['adventures'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == 'plage');

      expect(entry['title'], 'La plage en hiver');
    });
  });

  group('Les listes', () {
    test('celles qui existent deja ne sont pas reecrites', () async {
      // Le catalogue est global : une liste ecrite deux fois serait un doublon,
      // et le chargement refuserait le dossier entier.
      final written = await saveInto(shipped, shippedAdventure);

      expect(written.files.containsKey('lists/plage.json'), isFalse);
    });

    test('celles que l\'outil vient de creer sont ecrites et declarees',
        () async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Grisbie au marché',
        startName: 'Devant la maison',
      );
      final built = AdventureBuilder(fresh).addTrips(
        'devant_la_maison',
        const <NewTrip>[NewTrip(name: 'En bus')],
      );

      final written = await saveInto(shipped, built);
      final index = await indexOf(written);

      final lists = jsonDecode(written.files['lists/grisbie_au_marche.json']!)
          as Map<String, dynamic>;
      expect(
        (lists['lists'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((list) => list['id']),
        contains('en_bus'),
      );
      expect(index['lists'], contains('lists/grisbie_au_marche.json'));
    });

    test('sans liste nouvelle, aucun fichier vide n\'est pose', () async {
      final written = await saveInto(shipped, shippedAdventure);
      final index = await indexOf(written);

      expect((index['lists'] as List<dynamic>), <String>['lists/transport.json']);
    });
  });

  group('Ne rendre que ce qui vient d\'etre ecrit', () {
    test('le vocabulaire et les autres aventures restent ou ils sont',
        () async {
      // Quand la destination possede deja le reste — un depot, un dossier de
      // telechargement d'ou l'on repose les fichiers a la main — recopier le
      // lexique serait au mieux inutile.
      final written = await saveInto(
        shipped,
        shippedAdventure,
        includeUnchanged: false,
      );

      expect(written.files.keys, <String>[
        'adventures/plage.json',
        'index.json',
      ]);
    });

    test('le sommaire rendu declare quand meme tout ce qui existait', () async {
      // C'est le sommaire entier qu'on repose : n'y garder que l'aventure
      // enregistree effacerait les autres du depot.
      final index = await indexOf(
        await saveInto(shipped, shippedAdventure, includeUnchanged: false),
      );

      expect(index['lexicons'], <String>['lexicon/transport.json']);
      expect((index['adventures'] as List<dynamic>), hasLength(1));
    });
  });

  group('Le controle qui compte', () {
    test('le dossier ecrit se recharge, et l\'aventure est la', () async {
      final written = await saveInto(shipped, shippedAdventure);

      // Rien n'est relu depuis le contenu livre : le dossier ecrit se suffit.
      final reloaded =
          await ContentRepository(source: written).loadAdventure('plage');

      expect(reloaded.title, 'La plage');
      expect(reloaded.startStage.locationName, 'La gare');
      expect(
        reloaded.startStage.families.single.words.map((word) => word.text),
        <String>['quai', 'billet'],
      );
    });

    test('une aventure neuve s\'y recharge aussi, inachevee', () async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Grisbie au marché',
        startName: 'Devant la maison',
      );

      final written = await saveInto(shipped, fresh);
      final draft = await ContentRepository(source: written)
          .loadDraft('grisbie_au_marche');

      // C'est tout l'interet de `loadDraft` : rouvrir ce qu'on vient
      // d'enregistrer, meme incomplet.
      expect(draft.startStage.locationName, 'Devant la maison');
      expect(draft.validate(), isNotEmpty);
    });

    test('l\'aventure livree reste chargeable a cote de la neuve', () async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Grisbie au marché',
        startName: 'Devant la maison',
      );

      final written = await saveInto(shipped, fresh);
      final other =
          await ContentRepository(source: written).loadAdventure('plage');

      expect(other.id, 'plage');
    });
  });
}
