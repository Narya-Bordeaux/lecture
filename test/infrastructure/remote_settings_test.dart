import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/infrastructure/remote/author_session.dart';
import 'package:grisbie/infrastructure/remote/remote_settings.dart';

/// Ce qui, du dépôt distant, s'éprouve sans dépôt distant.
///
/// L'essentiel de Firebase ne se teste pas ici : ni les greffons, ni le
/// réseau, ni un compte. Ce fichier couvre les deux endroits qui pourraient
/// être faux **sans** qu'un appareil le dise — la configuration au lancement,
/// et la traduction des refus de connexion.

Map<String, String> completeValues() {
  return <String, String>{
    'apiKey': 'AIza-exemple',
    'appId': '1:123:android:abc',
    'projectId': 'narya-grisbie-dev',
    'messagingSenderId': '123',
    'storageBucket': 'narya-grisbie-dev.firebasestorage.app',
  };
}

void main() {
  group('La configuration du lancement', () {
    test('complète, elle se déclare utilisable', () {
      expect(RemoteSettings.fromValues(completeValues()).isComplete, isTrue);
    });

    test('absente, l\'outil s\'en passe au lieu d\'échouer', () {
      // C'est le cas ordinaire : le dépôt se compile et se lance sans clés, et
      // l'enregistrement reste local.
      final settings = RemoteSettings.fromValues(const <String, String>{});

      expect(settings.isComplete, isFalse);
      expect(settings.missingKeys, RemoteSettings.requiredKeys);
    });

    test('incomplète, elle nomme ce qui manque', () {
      // Ces valeurs se recopient une à une depuis une console : « configuration
      // incomplète » sans dire laquelle se chercherait à l'aveugle.
      final values = completeValues()..remove('storageBucket');

      expect(
        RemoteSettings.fromValues(values).missingKeys,
        <String>['storageBucket'],
      );
    });

    test('une valeur vide ou blanche ne compte pas', () {
      // `--dart-define` non renseigné donne une chaîne vide, pas une absence.
      final values = completeValues()..['apiKey'] = '   ';

      expect(RemoteSettings.fromValues(values).missingKeys, <String>['apiKey']);
    });

    test('le domaine de connexion n\'est pas exigé', () {
      // Il ne sert qu'au web : le rendre obligatoire empêcherait de lancer
      // l'outil sur un téléphone.
      final settings = RemoteSettings.fromValues(completeValues());

      expect(settings.authDomain, isNull);
      expect(settings.isComplete, isTrue);
    });
  });

  group('Un refus de connexion se lit', () {
    test('les codes courants sont traduits', () {
      expect(
        AuthorSession.describeFailure('invalid-credential'),
        'Adresse ou mot de passe incorrect.',
      );
      expect(
        AuthorSession.describeFailure('network-request-failed'),
        contains('réseau'),
      );
    });

    test('un code inconnu reste lisible, et se cite', () {
      // Mieux vaut un code brut dans une phrase qu'un écran muet : c'est ce
      // qu'on recopiera pour chercher.
      final message = AuthorSession.describeFailure('quota-exceeded');

      expect(message, contains('quota-exceeded'));
    });
  });
}
