import 'package:reading_game/domain/models/adventure.dart';

/// Source des aventures, vue par le moteur.
///
/// Le moteur ignore d'ou vient le contenu : fichier embarque aujourd'hui, autre
/// source demain. C'est ce qui permet de le tester sans Flutter.
abstract class AdventureRepository {
  Future<Adventure> loadAdventure(String adventureId);
}
