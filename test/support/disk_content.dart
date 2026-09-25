import 'dart:convert';
import 'dart:typed_data';

import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/infrastructure/content/content_repository.dart';
import 'package:grisbie/infrastructure/content/file_content_source.dart';

// Le depot en memoire vit dans `lib/` depuis que l'outil d'auteur s'en sert
// pour les essais ; les tests le retrouvent ici, comme avant.
export 'package:grisbie/infrastructure/content/preloaded_adventure_repository.dart';

/// Lit les fichiers de contenu livres, comme le ferait un auteur.
///
/// Les tests portant sur le contenu reel n'ont pas acces au bundle de
/// l'application : ils lisent les memes fichiers, directement. La lecture
/// elle-meme vient de `FileContentSource`, pour qu'il n'y en ait qu'une
/// version.
class DiskContentSource extends FileContentSource {
  const DiskContentSource({String basePath = 'assets/content'})
      : super(directory: basePath);
}

/// Le depot branche sur les fichiers livres.
ContentRepository buildDiskRepository() {
  return ContentRepository(source: const DiskContentSource());
}

/// L'aventure livree, mots et personnages resolus.
Future<Adventure> loadRealAdventure([String id = 'grisbie_plage']) {
  return buildDiskRepository().loadAdventure(id);
}

/// L'aventure livree, ouverte comme l'outil d'auteur l'ouvre : en brouillon,
/// sans lui opposer `validate()`.
///
/// Les tests de l'outil s'en servent. Ceux du jeu gardent [loadRealAdventure],
/// qui refuse, comme le jeu, une aventure incomplete.
Future<Adventure> loadRealDraft([String id = 'grisbie_plage']) {
  return buildDiskRepository().loadDraft(id);
}

/// L'aventure donnee, chaque trajet muni de ses deux textes obligatoires —
/// **des textes de test**, poses la ou l'auteur n'a encore rien ecrit.
///
/// Sert aux tests de l'outil qui ont besoin d'une aventure jouable, sans
/// dependre de l'avancement de l'ecriture. Jamais du contenu : ces textes ne
/// quittent pas les tests.
Adventure withTestTripTexts(Adventure adventure) {
  var completed = adventure;
  for (final stage in adventure.stages.values) {
    completed = completed.withStage(stage.copyWith(
      families: <WordFamily>[
        for (final family in stage.families)
          family.leadsSomewhere
              ? family.copyWith(
                  completionText: family.lacksCompletionText
                      ? 'Texte de test : « ${family.label} » est pleine.'
                      : null,
                  departureLabel: family.lacksDepartureLabel
                      ? 'Partir (test) ${family.label}'
                      : null,
                )
              : family,
      ],
    ));
  }
  return completed;
}

/// Sert les fichiers livres, sauf ceux qu'on remplace.
///
/// Permet de recharger une aventure fraichement ecrite avec le lexique et les
/// personnages reels, sans avoir a les redeclarer.
class OverridingContentSource implements ContentSource {
  const OverridingContentSource({
    required this.overrides,
    this.base = const DiskContentSource(),
  });

  final Map<String, String> overrides;
  final ContentSource base;

  @override
  Future<String> readFile(String path) async {
    return overrides[path] ?? await base.readFile(path);
  }

  @override
  Future<Uint8List> readBytes(String path) async {
    final replaced = overrides[path];
    if (replaced != null) return Uint8List.fromList(utf8.encode(replaced));

    return base.readBytes(path);
  }
}

/// Charge une aventure depuis un JSON donne, comme le ferait le jeu.
///
/// L'identifiant est lu dans le JSON lui-meme : c'est lui qui doit concorder
/// avec le sommaire, et s'en remettre a l'appelant masquerait l'erreur.
Future<Adventure> loadAdventureFrom({
  required String adventureJson,
  required String path,
}) {
  final id = (jsonDecode(adventureJson) as Map<String, dynamic>)['id'] as String;

  return ContentRepository(
    source: OverridingContentSource(
      overrides: <String, String>{path: adventureJson},
    ),
  ).loadAdventure(id);
}

