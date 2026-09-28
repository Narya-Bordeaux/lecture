import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/content_index.dart';

/// L'ordre du sommaire est celui de l'accueil : la premiere aventure se pose
/// a gauche de la roue. Il se regle a la main dans `index.json`, et un
/// enregistrement ne doit pas le defaire.
void main() {
  const index = ContentIndex(
    lexiconFiles: <String>[],
    adventures: <AdventureEntry>[
      AdventureEntry(id: 'premiere', title: 'Première', file: 'a.json'),
      AdventureEntry(id: 'seconde', title: 'Seconde', file: 'b.json'),
    ],
  );

  List<String> idsOf(ContentIndex index) => <String>[
    for (final entry in index.adventures) entry.id,
  ];

  test('reenregistrer une aventure la garde a sa place', () {
    final updated = index.withAdventure(
      const AdventureEntry(id: 'premiere', title: 'Renommée', file: 'a.json'),
    );

    expect(idsOf(updated), <String>['premiere', 'seconde']);
    expect(updated.adventures.first.title, 'Renommée');
  });

  test('une aventure nouvelle se range a la fin', () {
    final updated = index.withAdventure(
      const AdventureEntry(id: 'neuve', title: 'Neuve', file: 'c.json'),
    );

    expect(idsOf(updated), <String>['premiere', 'seconde', 'neuve']);
  });
}
