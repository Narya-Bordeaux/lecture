import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/infrastructure/content/asset_content_source.dart';
import 'package:grisbie/infrastructure/content/browser_content_sink.dart';
import 'package:grisbie/infrastructure/content/content_repository.dart';
import 'package:grisbie/infrastructure/content/content_saver.dart';
import 'package:grisbie/infrastructure/content/content_writer.dart';
import 'package:grisbie/infrastructure/content/device_content_folder.dart';
import 'package:grisbie/infrastructure/content/fallback_content_source.dart';
import 'package:grisbie/infrastructure/pictures/device_picture_library.dart';
import 'package:grisbie/infrastructure/remote/author_remote.dart';
import 'package:grisbie/ui/pages/author_home_page.dart';

/// La saveur Android sous laquelle cet outil doit tourner.
///
/// Voir `android/app/build.gradle.kts` : c'est la seule qui embarque la
/// configuration Firebase.
const String authorFlavor = 'auteur';

/// Point d'entree de l'outil d'auteur, distinct de celui du jeu.
///
/// Lancer ce fichier plutot que `main.dart` — sous Android Studio, « Run
/// 'main_author.dart' » — ouvre l'outil de calage des zones. Le jeu livre aux
/// enfants n'en contient aucune trace : aucun bouton cache, aucun geste secret
/// a decouvrir par megarde.
Future<void> main() async {
  // Une saveur Gradle ne choisit **pas** le point d'entree Dart : « --flavor »
  // et « -t » sont deux options independantes, que rien n'oblige a apparier.
  // Lance avec la saveur du jeu, l'outil n'aurait pas la configuration Firebase
  // et echouerait plus tard, plus loin, sans dire pourquoi. Autant le dire ici.
  //
  // Hors Android — Web, bureau, tests — la notion de saveur n'existe pas et
  // `appFlavor` est nul : il n'y a alors rien a verifier.
  assert(
    appFlavor == null || appFlavor == authorFlavor,
    'Outil d\'auteur lance avec la saveur "$appFlavor". Apparier les deux '
    'options :\n'
    '  flutter run --flavor $authorFlavor -t lib/main_author.dart',
  );

  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Le depot distant, s'il est configure. Absent, l'outil enregistre sur
  // l'appareil : une capacite manquante ne casse rien.
  final remote = await AuthorRemote.connect();

  // Le dossier de travail de l'appareil, resolu une fois pour toutes : lire et
  // ecrire doivent viser le meme endroit, et un navigateur n'en a pas.
  final deviceDirectory = kIsWeb ? null : await DeviceContentFolder.path();

  runApp(AuthorToolsApp(remote: remote, deviceDirectory: deviceDirectory));
}

/// D'ou l'outil lit le contenu, selon la connexion et la plateforme.
///
/// **Ce que l'outil a ecrit l'emporte, le contenu livre sert de repli.** Sans
/// repli, un premier lancement ne trouverait rien — le dossier de travail est
/// vide ; sans preference, l'outil ne verrait jamais ce qu'il vient
/// d'enregistrer, et on ecrirait une aventure sans pouvoir la rouvrir.
///
/// Connecte, c'est le depot distant qu'on lit : c'est lui qui fait communiquer
/// le poste et le telephone.
///
/// Dans un navigateur, il n'y a rien d'ecrit a relire — l'enregistrement y
/// descend en fichiers separes — et le contenu livre suffit.
ContentSource authorContentSource({
  required AuthorRemote? remote,
  required String? deviceDirectory,
}) {
  const shipped = AssetContentSource();

  if (remote != null && remote.account.isSignedIn) {
    return FallbackContentSource(preferred: remote.store, fallback: shipped);
  }
  if (deviceDirectory == null) return shipped;

  return FallbackContentSource(
    preferred: DeviceContentFolder.sourceAt(deviceDirectory),
    fallback: shipped,
  );
}

/// Ou va le contenu enregistre, selon la plateforme.
///
/// **Le contenu livre est scelle dans le bundle** : on lit d'un cote, on ecrit
/// de l'autre, et c'est le seul endroit qui sache lequel.
///
/// Sur un appareil, un dossier a nous, qui doit se suffire — l'appareil n'a
/// rien d'autre. Dans un navigateur, le telechargement, et seulement ce qui
/// vient d'etre ecrit : la destination est un depot qui possede deja le
/// lexique.
///
/// **On relit par ou l'on ecrit** : `includeUnchanged` recopie ce que l'outil
/// ne touche pas, dont les *autres* aventures. Les prendre au contenu livre
/// les y ramenerait a leur version d'origine, effacant en silence le travail
/// de la veille. La source est donc celle de l'outil, pas les assets.
Future<List<String>> saveAdventure(
  Adventure adventure, {
  AuthorRemote? remote,
  String? deviceDirectory,
}) async {
  final source = authorContentSource(
    remote: remote,
    deviceDirectory: deviceDirectory,
  );

  // Connecte, le contenu part sur le depot : c'est ce qui fait communiquer le
  // poste et le telephone. Il faut y recopier ce que l'outil ne touche pas,
  // comme sur un appareil — le depot distant part vide.
  if (remote != null && remote.account.isSignedIn) {
    return ContentSaver(
      source: source,
      writer: ContentWriter(sink: remote.store),
    ).save(adventure);
  }

  if (kIsWeb) {
    return ContentSaver(
      source: source,
      writer: ContentWriter(sink: browserContentSink()),
    ).save(adventure, includeUnchanged: false);
  }

  final directory = deviceDirectory ?? await DeviceContentFolder.path();

  return ContentSaver(
    source: source,
    writer: ContentWriter(sink: DeviceContentFolder.sinkAt(directory)),
  ).save(adventure);
}

class AuthorToolsApp extends StatelessWidget {
  const AuthorToolsApp({this.remote, this.deviceDirectory, super.key});

  /// Le depot distant, nul quand le lancement ne l'a pas configure.
  final AuthorRemote? remote;

  /// Le dossier de travail de l'appareil, nul dans un navigateur.
  final String? deviceDirectory;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Outil d\'auteur',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: AuthorHomePage(
        // Une fabrique, et non un depot deja ouvert : `ContentRepository`
        // garde le sommaire en memoire, si bien qu'il ne verrait pas ce qu'on
        // vient d'enregistrer — et se connecter change la source.
        openRepository: () => ContentRepository(
          source: authorContentSource(
            remote: remote,
            deviceDirectory: deviceDirectory,
          ),
        ),
        // La photothegue. **Le seul endroit du depot qui la construise**, et
        // il est dans l'outil d'auteur : le jeu n'a aucun chemin vers elle.
        //
        // Sur toutes les plateformes, desormais. Elle etait nulle dans un
        // navigateur, faute de disque ou ranger la copie — mais cela privait
        // le poste de tout chargement d'image, alors que c'est la qu'on
        // travaille au clavier. Ce qui differe, c'est ce qu'on peut garder,
        // et la photothegue le dit elle-meme.
        pictures: DevicePictureLibrary(),
        account: remote?.account,
        onSave: (adventure) => saveAdventure(
          adventure,
          remote: remote,
          deviceDirectory: deviceDirectory,
        ),
      ),
    );
  }
}
