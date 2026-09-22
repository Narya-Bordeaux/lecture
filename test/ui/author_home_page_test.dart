import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/repositories/author_account.dart';
import 'package:grisbie/infrastructure/content/content_repository.dart';
import 'package:grisbie/infrastructure/content/fallback_content_source.dart';
import 'package:grisbie/ui/pages/author_home_page.dart';
import 'package:grisbie/ui/pages/outline_page.dart';

import '../support/memory_content.dart';

/// L'ecran d'accueil de l'outil : ce qu'il montre, et d'ou il le lit.
///
/// Le defaut qu'il repare est le suivant : l'outil ecrivait ailleurs que dans
/// les assets — qui sont scelles au build — et relisait pourtant les assets.
/// On pouvait donc enregistrer une aventure et ne jamais la rouvrir.

/// Le contenu livre : une aventure jouable, en resume.
Map<String, String> shippedFiles() {
  return <String, String>{
    'index.json': '''
{
  "lexicons": ["lexicon/test.json"],
  "lists": ["lists/test.json"],
  "adventures": [
    { "id": "plage", "title": "La plage", "file": "adventures/plage.json" }
  ]
}''',
    'lexicon/test.json':
        '{ "domain": "test", "words": [ { "text": "un", "syllables": ["un"] } ] }',
    'lists/test.json':
        '{ "domain": "test", "lists": [ { "id": "vide", "name": "Vide", "words": [] } ] }',
    'adventures/plage.json': '''
{
  "id": "plage",
  "title": "La plage",
  "startStageId": "depart",
  "stages": [ { "id": "depart", "location": "Depart", "ending": true } ]
}''',
  };
}

/// Ce que l'auteur vient d'ecrire : une aventure de plus, **inachevee**.
///
/// Son lieu de depart n'a ni famille ni marqueur de fin : `loadAdventure` la
/// refuserait. C'est l'etat normal d'un lieu qu'on vient de creer.
Map<String, String> writtenFiles() {
  return <String, String>{
    'index.json': '''
{
  "lexicons": ["lexicon/test.json"],
  "lists": ["lists/test.json"],
  "adventures": [
    { "id": "plage", "title": "La plage", "file": "adventures/plage.json" },
    { "id": "gare", "title": "La gare", "file": "adventures/gare.json" }
  ]
}''',
    'adventures/gare.json': '''
{
  "id": "gare",
  "title": "La gare",
  "startStageId": "quai",
  "stages": [ { "id": "quai", "location": "Le quai" } ]
}''',
  };
}

/// Un compte qui ne contacte rien.
class FakeAuthorAccount implements AuthorAccount {
  FakeAuthorAccount({required this.signedIn});

  bool signedIn;

  @override
  String? get userId => signedIn ? 'uid-de-l-auteur' : null;

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    signedIn = true;
    return null;
  }

  @override
  Future<void> signOut() async => signedIn = false;
}

void main() {
  late MemoryContentFolder shipped;
  late MemoryContentFolder written;
  late int opened;

  /// Le montage reel de l'outil : ce qui est ecrit l'emporte, le contenu livre
  /// sert de repli, et le depot se rouvre a neuf a chaque fois.
  ContentRepository openRepository() {
    opened += 1;
    return ContentRepository(
      source: FallbackContentSource(preferred: written, fallback: shipped),
    );
  }

  setUp(() {
    shipped = MemoryContentFolder(shippedFiles());
    written = MemoryContentFolder();
    opened = 0;
  });

  Future<void> pumpHome(WidgetTester tester, {AuthorAccount? account}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthorHomePage(
          openRepository: openRepository,
          account: account,
          onSave: (adventure) async => <String>[],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sans rien d\'ecrit, l\'accueil montre le contenu livre',
      (tester) async {
    await pumpHome(tester);

    expect(find.text('La plage'), findsOneWidget);
    expect(find.text('La gare'), findsNothing);
  });

  testWidgets('ce que l\'outil a ecrit apparait', (tester) async {
    written.files.addAll(writtenFiles());

    await pumpHome(tester);

    // Le sommaire vient du travail ; l'aventure livree reste lisible, son
    // fichier n'ayant pas ete reecrit.
    expect(find.text('La gare'), findsOneWidget);
    expect(find.text('La plage'), findsOneWidget);
  });

  testWidgets('une aventure inachevee s\'ouvre quand meme', (tester) async {
    // C'est tout l'interet de `loadDraft` : un lieu qu'on vient de creer n'a
    // pas ses mots, et `loadAdventure` refuserait de rouvrir le fichier.
    written.files.addAll(writtenFiles());

    await pumpHome(tester);
    await tester.tap(find.text('La gare'));
    await tester.pumpAndSettle();

    expect(find.byType(OutlinePage), findsOneWidget);
    expect(find.textContaining('illisible'), findsNothing);
  });

  testWidgets('un contenu illisible se dit, sans faire disparaitre l\'ecran',
      (tester) async {
    written.files.addAll(writtenFiles());
    written.files['adventures/gare.json'] = '{{{ pas du JSON';

    await pumpHome(tester);
    await tester.tap(find.text('La gare'));
    await tester.pumpAndSettle();

    expect(find.byType(OutlinePage), findsNothing);
    expect(find.textContaining('illisible'), findsOneWidget);
  });

  testWidgets('se deconnecter rouvre le contenu', (tester) async {
    // Le depot garde le sommaire en memoire, et l'on ne lit plus au meme
    // endroit : sans reouverture, l'ecran montrerait le contenu du depot
    // distant a quelqu'un qui n'y est plus connecte.
    await pumpHome(tester, account: FakeAuthorAccount(signedIn: true));
    expect(opened, 1);

    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();

    expect(opened, 2);
  });
}
