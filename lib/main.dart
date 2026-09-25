import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grisbie/infrastructure/content/asset_content_source.dart';
import 'package:grisbie/infrastructure/content/content_repository.dart';
import 'package:grisbie/ui/pages/game_home_page.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait uniquement pour l'instant : l'illustration est cadree ainsi, et
  // l'orientation reste a traiter (voir docs/TODO.md).
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const GrisbieApp());
}

class GrisbieApp extends StatelessWidget {
  const GrisbieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: UiStringsFr.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      // L'accueil propose toutes les aventures du sommaire : le jeu ne
      // demande plus d'aventure par son nom.
      home: GameHomePage(
        repository: ContentRepository(
          source: const AssetContentSource(),
        ),
      ),
    );
  }
}
