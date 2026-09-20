import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reading_game/infrastructure/content/asset_content_source.dart';
import 'package:reading_game/infrastructure/content/content_repository.dart';
import 'package:reading_game/ui/pages/adventure_page.dart';
import 'package:reading_game/ui/strings/ui_strings_fr.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait uniquement pour l'instant : l'illustration est cadree ainsi, et
  // l'orientation reste a traiter (voir docs/TODO.md).
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ReadingGameApp());
}

class ReadingGameApp extends StatelessWidget {
  const ReadingGameApp({super.key});

  /// L'aventure du niveau test, seule disponible a ce stade.
  static const String _defaultAdventureId = 'grisbie_beach';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: UiStringsFr.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: AdventurePage(
        repository: ContentRepository(
          source: const AssetContentSource(),
        ),
        adventureId: _defaultAdventureId,
      ),
    );
  }
}
