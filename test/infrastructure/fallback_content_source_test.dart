import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/repositories/content_file_not_found.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/infrastructure/content/fallback_content_source.dart';

import '../support/memory_content.dart';

/// Lire son travail par-dessus le contenu livré.
///
/// L'outil d'auteur écrit ailleurs que dans les assets, qui sont scellés au
/// build. Au premier lancement, ce « ailleurs » est vide : il n'y a que le
/// contenu livré. Après un premier enregistrement, c'est le travail qui fait
/// foi — et il doit faire foi **entièrement**, sinon une aventure rouverte
/// mélangerait la version écrite et celle d'origine.

/// Une source qui tombe en panne, comme un dépôt hors d'atteinte.
class BrokenContentSource implements ContentSource {
  const BrokenContentSource(this.failure);

  final Object failure;

  @override
  Future<String> readFile(String path) async => throw failure;
}

void main() {
  late MemoryContentFolder shipped;
  late MemoryContentFolder working;
  late FallbackContentSource source;

  setUp(() {
    shipped = MemoryContentFolder(<String, String>{
      'index.json': '{ "livre": true }',
      'lexicon/transport.json': '{ "mots": "livres" }',
    });
    working = MemoryContentFolder();
    source = FallbackContentSource(preferred: working, fallback: shipped);
  });

  test('sans rien d\'écrit, tout vient du contenu livré', () async {
    // Le premier lancement : l'outil ouvre l'aventure livrée, comme avant.
    expect(await source.readFile('index.json'), '{ "livre": true }');
  });

  test('un fichier écrit l\'emporte sur celui d\'origine', () async {
    working.files['index.json'] = '{ "ecrit": true }';

    expect(await source.readFile('index.json'), '{ "ecrit": true }');
  });

  test('les fichiers non réécrits restent lisibles', () async {
    // Le cas du navigateur, où l'enregistrement ne rend que ce qui a changé :
    // le lexique n'a pas bougé et doit rester trouvable.
    working.files['index.json'] = '{ "ecrit": true }';

    expect(
      await source.readFile('lexicon/transport.json'),
      '{ "mots": "livres" }',
    );
  });

  test('un fichier absent des deux est signalé', () async {
    // Ni l'un ni l'autre ne l'a : c'est une vraie absence, pas un repli.
    expect(
      () => source.readFile('adventures/inconnue.json'),
      throwsA(isA<ContentFileNotFound>()),
    );
  });

  test('le repli ne masque pas un travail illisible', () async {
    // Un fichier écrit mais corrompu doit échouer au chargement, pas se faire
    // remplacer en silence par la version livrée : l'auteur croirait son
    // travail intact.
    working.files['index.json'] = '{{{ pas du JSON';

    expect(await source.readFile('index.json'), '{{{ pas du JSON');
  });

  group('Une panne n\'est pas une absence', () {
    // **Le défaut que ce groupe répare.** Le repli attrapait tout : un refus
    // du dépôt, une panne de réseau ou un blocage du navigateur servaient
    // silencieusement le contenu livré. L'auteur enregistrait son aventure,
    // ne la retrouvait pas dans la liste, et rien ne lui disait pourquoi.

    test('un dépôt hors d\'atteinte se signale, il ne se contourne pas',
        () async {
      final broken = FallbackContentSource(
        preferred: const BrokenContentSource('accès refusé par le dépôt'),
        fallback: shipped,
      );

      expect(
        () => broken.readFile('index.json'),
        throwsA('accès refusé par le dépôt'),
      );
    });

    test('mais une absence, elle, se replie', () async {
      final empty = FallbackContentSource(
        preferred: const BrokenContentSource(ContentFileNotFound('index.json')),
        fallback: shipped,
      );

      expect(await empty.readFile('index.json'), '{ "livre": true }');
    });
  });
}
