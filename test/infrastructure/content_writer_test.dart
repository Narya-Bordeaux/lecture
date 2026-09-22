import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/repositories/content_sink.dart';
import 'package:grisbie/infrastructure/content/content_writer.dart';

import '../support/disk_content.dart';

/// Recueille ce qui serait ecrit, sans toucher au disque.
class MemoryContentSink implements ContentSink {
  final Map<String, String> files = <String, String>{};

  @override
  Future<void> writeFile(String path, String contents) async {
    files[path] = contents;
  }

  /// Ces tests portent sur la fidelite du JSON ; les octets n'y servent qu'a
  /// satisfaire le contrat.
  @override
  Future<void> writeBytes(String path, Uint8List contents) async {
    files[path] = '<${contents.length} octets>';
  }
}

/// Verifie que tout ce que contient [original] se retrouve dans [written].
///
/// Une comparaison stricte serait trop severe : l'ecriture explicite des
/// valeurs par defaut qu'un auteur avait laissees implicites. C'est l'inverse
/// qui serait grave — un champ du fichier livre qui disparaitrait a
/// l'enregistrement, sans que rien ne le signale.
void expectNothingLost(Object? original, Object? written, {String path = ''}) {
  if (original is Map) {
    expect(
      written,
      isA<Map<String, dynamic>>(),
      reason: 'À "$path", un objet est attendu mais absent',
    );
    final writtenMap = written! as Map<String, dynamic>;
    for (final entry in original.entries) {
      final key = entry.key as String;
      expect(
        writtenMap.containsKey(key),
        isTrue,
        reason: 'Champ perdu à l\'ecriture : "$path/$key"',
      );
      expectNothingLost(entry.value, writtenMap[key], path: '$path/$key');
    }
    return;
  }

  if (original is List) {
    expect(
      written,
      isA<List<dynamic>>(),
      reason: 'À "$path", une liste est attendue mais absente',
    );
    final writtenList = written! as List<dynamic>;
    expect(
      writtenList,
      hasLength(original.length),
      reason: 'Liste de taille differente à "$path"',
    );
    for (var index = 0; index < original.length; index++) {
      expectNothingLost(
        original[index],
        writtenList[index],
        path: '$path[$index]',
      );
    }
    return;
  }

  expect(original, written, reason: 'Valeur changée à "$path"');
}

void main() {
  const adventurePath = 'adventures/grisbie_plage.json';

  const listPaths = <String>['lists/transport.json', 'lists/quotidien.json'];

  late Adventure adventure;
  late Map<String, dynamic> originalFile;

  /// Les listes livrees, telles qu'elles sont ecrites sur le disque.
  final originalLists = <String, Map<String, dynamic>>{};

  setUpAll(() async {
    adventure = await loadRealAdventure();
    originalFile = jsonDecode(
      await const DiskContentSource().readFile(adventurePath),
    ) as Map<String, dynamic>;

    for (final path in listPaths) {
      final file = jsonDecode(await const DiskContentSource().readFile(path))
          as Map<String, dynamic>;
      for (final item in file['lists'] as List<dynamic>) {
        final list = item as Map<String, dynamic>;
        originalLists[list['id'] as String] = list;
      }
    }
  });

  group('Ecriture d\'une aventure', () {
    test('rien de ce que contient le fichier livre n\'est perdu', () async {
      // Le test qui compte : l'outil d'auteur reecrit ce fichier, et un champ
      // que la serialisation oublierait disparaitrait du contenu sans bruit.
      final sink = MemoryContentSink();
      await ContentWriter(sink: sink).writeAdventure(
        adventure,
        path: adventurePath,
      );

      final written = jsonDecode(sink.files[adventurePath]!)
          as Map<String, dynamic>;

      expectNothingLost(originalFile, written);
    });

    test('le fichier reecrit se recharge a l\'identique', () async {
      final sink = MemoryContentSink();
      await ContentWriter(sink: sink).writeAdventure(
        adventure,
        path: adventurePath,
      );

      final reloaded = await loadAdventureFrom(
        adventureJson: sink.files[adventurePath]!,
        path: adventurePath,
      );

      expect(
        jsonEncode(reloaded.toJson()),
        jsonEncode(adventure.toJson()),
      );
    });

    test('reecrire deux fois donne le meme fichier', () async {
      // Sans cette stabilite, ouvrir puis fermer l'outil sans rien changer
      // produirait une difference dans git a chaque fois.
      final first = MemoryContentSink();
      await ContentWriter(sink: first).writeAdventure(
        adventure,
        path: adventurePath,
      );

      final reloaded = await loadAdventureFrom(
        adventureJson: first.files[adventurePath]!,
        path: adventurePath,
      );
      final second = MemoryContentSink();
      await ContentWriter(sink: second).writeAdventure(
        reloaded,
        path: adventurePath,
      );

      expect(second.files[adventurePath], first.files[adventurePath]);
    });

    test('le fichier ecrit reste lisible par un humain', () async {
      // Le contenu est destine a etre relu par un enseignant ou un parent, et
      // c'est le point d'entree d'une contribution exterieure : une seule
      // longue ligne de JSON fermerait cette porte.
      final sink = MemoryContentSink();
      await ContentWriter(sink: sink).writeAdventure(
        adventure,
        path: adventurePath,
      );

      final text = sink.files[adventurePath]!;

      expect(text.split('\n').length, greaterThan(20));
      expect(text, contains('\n  "title"'));
      expect(text.endsWith('\n'), isTrue);
    });
  });

  group('Ecriture des listes de mots', () {
    const writtenPath = 'lists/ecrites.json';

    /// Les listes ecrites par l'outil, indexees par identifiant.
    Future<Map<String, dynamic>> writeLists() async {
      final sink = MemoryContentSink();
      await ContentWriter(sink: sink).writeWordLists(
        adventure.wordLists,
        path: writtenPath,
      );

      final file = jsonDecode(sink.files[writtenPath]!) as Map<String, dynamic>;
      return <String, dynamic>{
        for (final item in file['lists'] as List<dynamic>)
          (item as Map<String, dynamic>)['id'] as String: item,
      };
    }

    test('aucune liste citee ne reste sans fichier', () async {
      // Enregistrer une aventure sans ses listes la rendrait illisible au
      // rechargement suivant : elle citerait des listes que personne n'a
      // ecrites. C'est la panne que ce test interdit.
      final written = await writeLists();

      final cited = <String>{
        for (final stage in adventure.stages.values)
          for (final family in stage.families) family.list.id,
      };
      expect(written.keys, containsAll(cited));
    });

    test('rien de ce que contient un fichier de listes n\'est perdu', () async {
      final written = await writeLists();

      for (final entry in originalLists.entries) {
        expect(
          written.containsKey(entry.key),
          isTrue,
          reason: 'Liste perdue a l\'ecriture : "${entry.key}"',
        );
        // Le meme controle champ par champ que pour l'aventure : un mot qui
        // disparaitrait a l'enregistrement ne se verrait nulle part ailleurs.
        expectNothingLost(entry.value, written[entry.key]);
      }
    });
  });
}
