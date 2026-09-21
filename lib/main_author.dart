import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grisbie/infrastructure/content/asset_content_source.dart';
import 'package:grisbie/infrastructure/content/content_repository.dart';
import 'package:grisbie/main.dart';
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
void main() {
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

  runApp(const AuthorToolsApp());
}

class AuthorToolsApp extends StatelessWidget {
  const AuthorToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calage des zones',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: AuthorHomePage(
        repository: ContentRepository(source: const AssetContentSource()),
        // La meme aventure que le jeu : l'outil cale ce qui sera joue.
        adventureId: GrisbieApp.defaultAdventureId,
      ),
    );
  }
}
