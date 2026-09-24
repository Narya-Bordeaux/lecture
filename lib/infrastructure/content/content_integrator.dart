import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/repositories/content_file_not_found.dart';
import 'package:grisbie/domain/repositories/content_store.dart';
import 'package:grisbie/infrastructure/content/content_saver.dart';
import 'package:grisbie/infrastructure/content/content_writer.dart';

/// Verse une aventure dans le dossier du contenu du depot git
/// (`assets/content/`), pour qu'elle soit jouable a la compilation suivante.
///
/// **Le dossier du depot est la base** : c'est son sommaire, ce sont ses
/// listes et ses lexiques que l'aventure complete, ou corrige la ou ils
/// vivent — le meme `ContentSaver` que l'enregistrement, lisant et ecrivant
/// au meme endroit. Seul ce qui change est ecrit : le reste y est deja, et le
/// recopier ne ferait que produire des differences a relire au commit.
///
/// **Rien ne s'ecrit tant qu'un controle echoue.** Un depot a moitie modifie
/// serait pire qu'un refus : le jeu refuserait de s'ouvrir, et l'on ne
/// saurait plus ce qui a ete verse.
class ContentIntegrator {
  const ContentIntegrator({required this.folder, this.indexPath = 'index.json'});

  /// Le dossier du contenu du depot, lu et ecrit.
  final ContentStore folder;

  final String indexPath;

  /// Verse l'aventure et rend les chemins ecrits, ou refuse par
  /// [IntegrationRefused] en nommant chaque raison.
  Future<List<String>> integrate(Adventure adventure) async {
    final reasons = await reasonsToRefuse(adventure);
    if (reasons.isNotEmpty) throw IntegrationRefused(reasons);

    return ContentSaver(
      source: folder,
      writer: ContentWriter(sink: folder),
      indexPath: indexPath,
    ).save(adventure, includeUnchanged: false);
  }

  /// Ce qui empeche de verser l'aventure dans ce dossier. Vide, rien.
  Future<List<String>> reasonsToRefuse(Adventure adventure) async {
    // Le sommaire d'abord : sans lui, ce n'est pas le dossier du contenu, et
    // le reste des controles n'aurait pas de sens. Designer `assets/` ou la
    // racine du depot par megarde ecrirait l'aventure la ou le jeu ne la
    // chercherait jamais.
    if (!await _exists(indexPath, asText: true)) {
      return <String>[
        'Ce dossier n\'est pas « assets/content/ » : « $indexPath » n\'y '
            'est pas.',
      ];
    }

    return <String>[
      // Le meme contrat que le jeu : ce qu'il refuserait ne se verse pas.
      for (final issue in adventure.validate())
        if (issue.blocksPlay) issue.toString(),
      for (final path in adventure.picturePaths.toList()..sort())
        if (!await _exists(path, asText: false))
          'L\'image « $path » n\'est pas dans le dépôt : versez-la dans '
              '« assets/content/pictures/ ».',
    ];
  }

  /// Vrai si le fichier existe. Une absence se dit ; une panne remonte.
  Future<bool> _exists(String path, {required bool asText}) async {
    try {
      if (asText) {
        await folder.readFile(path);
      } else {
        await folder.readBytes(path);
      }
      return true;
    } on ContentFileNotFound {
      return false;
    }
  }
}

/// L'integration refusee, avec chaque raison — a montrer telles quelles.
class IntegrationRefused implements Exception {
  const IntegrationRefused(this.reasons);

  final List<String> reasons;

  @override
  String toString() => 'Intégration refusée :\n- ${reasons.join('\n- ')}';
}
