import 'package:grisbie/domain/repositories/content_source.dart';

/// Lit le travail de l'auteur par-dessus le contenu livre.
///
/// Les assets sont **scelles au build** : l'outil ecrit ailleurs — un dossier
/// de l'appareil, un depot distant — et cet ailleurs est vide au premier
/// lancement. Sans repli, l'outil ne trouverait rien ; sans preference, il ne
/// verrait jamais ce qu'il vient d'enregistrer.
///
/// La regle est donc : **ce qui est ecrit l'emporte, fichier par fichier**.
/// C'est ce qu'il faut pour le navigateur, dont l'enregistrement ne rend que ce
/// qui a change : le lexique non reecrit reste lu dans les assets.
///
/// Le repli ne s'applique qu'a l'**absence**. Un fichier ecrit mais illisible
/// echoue au chargement plutot que d'etre remplace en silence par la version
/// livree : l'auteur croirait son travail intact.
class FallbackContentSource implements ContentSource {
  const FallbackContentSource({
    required this.preferred,
    required this.fallback,
  });

  /// La ou l'outil ecrit.
  final ContentSource preferred;

  /// Le contenu livre, scelle dans le bundle.
  final ContentSource fallback;

  @override
  Future<String> readFile(String path) async {
    try {
      return await preferred.readFile(path);
    } catch (_) {
      // Un fichier jamais ecrit : c'est le cas ordinaire, pas une panne.
      return fallback.readFile(path);
    }
  }
}
