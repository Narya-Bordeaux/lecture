import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/repositories/author_account.dart';
import 'package:grisbie/ui/pages/author_sign_in_page.dart';

/// Se connecter au dépôt distant, sans dépôt distant.
///
/// L'écran ne sait rien du fournisseur : il montre un état et transmet deux
/// gestes, à travers [AuthorAccount]. C'est ce qui rend ces tests possibles —
/// ni Firebase, ni réseau, ni compte.

/// Un compte qui accepte ou refuse, sans rien contacter.
class FakeAuthorAccount implements AuthorAccount {
  FakeAuthorAccount({this.failure});

  /// Ce que la connexion rendra. Nul : elle réussit.
  final String? failure;

  String? _userId;
  String? askedEmail;

  @override
  String? get userId => _userId;

  @override
  bool get isSignedIn => _userId != null;

  @override
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    askedEmail = email;
    if (failure != null) return failure;
    _userId = 'uid-de-l-auteur';
    return null;
  }

  @override
  Future<void> signOut() async => _userId = null;
}

/// Monte l'écran et rend ce qu'il renvoie à la fermeture.
Future<bool?> pumpSignIn(WidgetTester tester, AuthorAccount account) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => AuthorSignInPage(account: account),
              ),
            );
          },
          child: const Text('ouvrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return result;
}

/// Saisit les deux champs et valide.
Future<void> fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('email')), 'auteur@exemple.test');
  await tester.enterText(find.byKey(const Key('password')), 'motdepasse');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Se connecter'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sans les deux champs, on ne peut pas valider', (tester) async {
    await pumpSignIn(tester, FakeAuthorAccount());

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('l\'adresse est transmise débarrassée de ses blancs',
      (tester) async {
    final account = FakeAuthorAccount();
    await pumpSignIn(tester, account);

    await tester.enterText(
      find.byKey(const Key('email')),
      '  auteur@exemple.test ',
    );
    await tester.enterText(find.byKey(const Key('password')), 'motdepasse');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    // Un espace collé par un gestionnaire de mots de passe ferait refuser la
    // connexion sans qu'on voie pourquoi.
    expect(account.askedEmail, 'auteur@exemple.test');
  });

  testWidgets('la connexion réussie ferme l\'écran', (tester) async {
    final account = FakeAuthorAccount();
    await pumpSignIn(tester, account);
    await fillAndSubmit(tester);

    expect(account.isSignedIn, isTrue);
    expect(find.text('Se connecter'), findsNothing);
  });

  testWidgets('un refus se lit, et l\'écran reste ouvert', (tester) async {
    // Un échec muet laisserait croire à une panne de réseau, et on
    // recommencerait le même mot de passe.
    await pumpSignIn(
      tester,
      FakeAuthorAccount(failure: 'Adresse ou mot de passe incorrect.'),
    );
    await fillAndSubmit(tester);

    expect(find.text('Adresse ou mot de passe incorrect.'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
