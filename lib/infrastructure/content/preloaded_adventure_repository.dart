import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_index.dart';
import 'package:grisbie/domain/repositories/adventure_repository.dart';

/// Sert une aventure deja en memoire, sans rien relire.
///
/// L'outil d'auteur s'en sert pour **jouer l'aventure telle qu'elle est a
/// l'ecran**, enregistree ou non : c'est ce qu'il vient de regler que l'auteur
/// veut eprouver sur l'appareil. Les tests de widget s'en servent aussi, pour
/// une autre raison : `pumpAndSettle` n'attend pas les entrees-sorties
/// reelles, et un depot qui lit des fichiers pendant le rendu laisse le test
/// tourner sans fin.
///
/// **Le meme contrat que le jeu** : une aventure injouable est refusee, comme
/// `ContentRepository.loadAdventure` la refuserait. Un essai qui ouvrirait ce
/// que le jeu refuse ne prouverait rien.
class PreloadedAdventureRepository implements AdventureRepository {
  PreloadedAdventureRepository(this.adventure);

  final Adventure adventure;

  @override
  Future<ContentIndex> loadIndex() async {
    return ContentIndex(
      lexiconFiles: const <String>[],
      adventures: <AdventureEntry>[
        AdventureEntry(
          id: adventure.id,
          title: adventure.title,
          file: '',
          coverAsset: adventure.coverAsset,
        ),
      ],
    );
  }

  @override
  Future<Adventure> loadAdventure(String adventureId) async {
    if (adventureId != adventure.id) {
      throw FormatException('Aventure inconnue : "$adventureId".');
    }
    final blocking =
        adventure.validate().where((issue) => issue.blocksPlay).toList();
    if (blocking.isNotEmpty) {
      throw FormatException(
        'Aventure injouable :\n- ${blocking.join('\n- ')}',
      );
    }
    return adventure;
  }
}
