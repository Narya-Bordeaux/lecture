import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:grisbie/infrastructure/remote/author_session.dart';
import 'package:grisbie/infrastructure/remote/remote_content_store.dart';
import 'package:grisbie/infrastructure/remote/remote_settings.dart';

/// Le depot distant de l'auteur, monte au lancement — ou pas du tout.
///
/// **Firebase ne s'initialise jamais tout seul ici.** Le montage prevu passait
/// par « google-services.json », qu'Android lit au demarrage sans qu'on le lui
/// demande ; il a ete ecarte pour deux raisons. Le greffon Gradle qui produit
/// ce fichier **echoue quand il manque**, ce qui aurait casse la saveur du jeu.
/// Et surtout, des options explicites suppriment l'auto-initialisation :
/// le jeu ne peut pas contacter Firebase, meme par megarde, puisque rien ne
/// l'initialise.
///
/// Les valeurs arrivent par `--dart-define` (voir `docs/Commandes.md`) : rien
/// dans le depot, rien a ignorer par git, et le projet se compile sans elles.
class AuthorRemote {
  const AuthorRemote({required this.account, required this.store});

  final AuthorSession account;
  final RemoteContentStore store;

  /// Ce que le lancement a fourni.
  static RemoteSettings get settings {
    return RemoteSettings.fromValues(const <String, String>{
      'apiKey': String.fromEnvironment('GRISBIE_FIREBASE_API_KEY'),
      'appId': String.fromEnvironment('GRISBIE_FIREBASE_APP_ID'),
      'projectId': String.fromEnvironment('GRISBIE_FIREBASE_PROJECT_ID'),
      'messagingSenderId':
          String.fromEnvironment('GRISBIE_FIREBASE_SENDER_ID'),
      'storageBucket': String.fromEnvironment('GRISBIE_FIREBASE_BUCKET'),
      'authDomain': String.fromEnvironment('GRISBIE_FIREBASE_AUTH_DOMAIN'),
    });
  }

  /// Monte le depot, ou rend `null` si le lancement ne l'a pas configure.
  ///
  /// Une capacite manquante ne casse rien : l'outil enregistre alors en local,
  /// exactement comme avant. C'est le meme parti que la photothegue.
  static Future<AuthorRemote?> connect() async {
    final settings = AuthorRemote.settings;
    if (!settings.isComplete) return null;

    final app = await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: settings.apiKey,
        appId: settings.appId,
        messagingSenderId: settings.messagingSenderId,
        projectId: settings.projectId,
        storageBucket: settings.storageBucket,
        authDomain: settings.authDomain,
      ),
    );

    return AuthorRemote(
      account: AuthorSession(auth: FirebaseAuth.instanceFor(app: app)),
      store: RemoteContentStore(storage: FirebaseStorage.instanceFor(app: app)),
    );
  }
}
