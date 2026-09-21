import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_index.dart';

/// Source des aventures, vue par l'interface.
///
/// L'interface ignore d'ou vient le contenu : fichiers embarques aujourd'hui,
/// autre source demain. C'est ce qui permet de tester le jeu sans Flutter.
abstract class AdventureRepository {
  /// Ce qui existe, sans charger les aventures elles-memes.
  Future<ContentIndex> loadIndex();

  /// Une aventure complete, mots et personnages resolus.
  Future<Adventure> loadAdventure(String adventureId);
}
