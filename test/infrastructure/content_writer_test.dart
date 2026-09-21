import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_game/domain/models/adventure.dart';
import 'package:reading_game/domain/repositories/content_sink.dart';
import 'package:reading_game/infrastructure/content/content_writer.dart';

import '../support/disk_content.dart';

/// Recueille ce qui serait ecrit, sans toucher au disque.
class MemoryContentSink implements ContentSink {
  final Map<String, String> files = <String, String>{};

  @override
  Future<void> writeFile(String path, String contents) async {
    files[path] = contents;
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

  late Adventure adventure;
  late Map<String, dynamic> originalFile;

  setUpAll(() async {
    adventure = await loadRealAdventure();
    originalFile = jsonDecode(
      await const DiskContentSource().readFile(adventurePath),
    ) as Map<String, dynamic>;
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
}
