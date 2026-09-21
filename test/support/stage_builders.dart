import 'package:grisbie/domain/models/narrative.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/models/word_list.dart';

/// Fabriques d'etapes pour les tests.
///
/// Les mots viennent normalement du lexique, resolus au chargement. Les tests
/// du moteur n'ont pas besoin de ce detour : ils declarent leurs mots sur
/// place, ce qui garde chaque test lisible d'un seul tenant.

/// Un mot, dont le decoupage vaut par defaut le mot entier.
Word word(String text, [List<String>? syllables]) {
  return Word(
    text: text,
    syllables: syllables ?? <String>[text],
  );
}

/// Une liste de mots, nommee d'apres son identifiant.
WordList wordList(String id, List<Word> words) {
  return WordList(id: id, name: id, words: words);
}

/// Une famille et la liste qu'elle cite.
///
/// Les mots se declarent ici plutot que dans un catalogue : un test du moteur
/// n'a que faire du detour par les references, et reste lisible d'un seul
/// tenant. Passer [list] permet a deux familles de citer **la meme** liste,
/// ce que le contenu reel fait d'un lieu a l'autre.
WordFamily family({
  required String id,
  required String label,
  List<Word>? words,
  WordList? list,
  String? destination,
  RelativeArea? area,
  int? goal,
  int? drawCount,
}) {
  return WordFamily(
    id: id,
    label: label,
    list: list ?? wordList(id, words ?? const <Word>[]),
    destinationStageId: destination,
    area: area,
    goal: goal,
    drawCount: drawCount,
  );
}

/// Une etape prete a jouer.
Stage stage({
  required String id,
  required List<WordFamily> families,
  String location = 'Un lieu',
  String? arrivalText,
  int visibleWordCount = 6,
  bool ending = false,
  int? drawCount,
}) {
  return Stage(
    id: id,
    locationName: location,
    narrative: Narrative(onArrival: arrivalText),
    families: families,
    visibleWordCount: visibleWordCount,
    isEnding: ending,
    drawCount: drawCount,
  );
}

/// Une etape qui clot le parcours : declaree comme telle, et sans famille.
Stage ending({required String id, String location = 'Une fin'}) {
  return stage(
    id: id,
    families: const <WordFamily>[],
    location: location,
    ending: true,
  );
}
