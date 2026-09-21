import 'package:grisbie/domain/models/narrative.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';

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

/// Une famille portant directement ses mots.
WordFamily family({
  required String id,
  required String label,
  required List<Word> words,
  String? destination,
  RelativeArea? area,
  int? goal,
}) {
  return WordFamily(
    id: id,
    label: label,
    words: words,
    destinationStageId: destination,
    area: area,
    goal: goal,
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
}) {
  return Stage(
    id: id,
    locationName: location,
    narrative: Narrative(onArrival: arrivalText),
    families: families,
    visibleWordCount: visibleWordCount,
    isEnding: ending,
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
