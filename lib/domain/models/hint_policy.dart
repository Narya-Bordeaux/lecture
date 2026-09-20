import 'package:reading_game/domain/models/hint.dart';

/// A partir de combien d'erreurs sur un meme mot chaque aide se debloque.
///
/// Les valeurs par defaut sont celles de la specification. L'ecart entre les
/// deux seuils est volontaire : le decoupage arrive des la premiere erreur car
/// il aide a dechiffrer sans livrer le sens, l'illustration attend un effort
/// prolonge car elle donne presque la reponse.
///
/// La classe est injectable pour que les niveaux puissent un jour faire varier
/// ces seuils sans toucher au moteur.
class HintPolicy {
  const HintPolicy({
    this.syllablesThreshold = 1,
    this.illustrationThreshold = 5,
  })  : assert(syllablesThreshold > 0, 'Un seuil se compte en erreurs.'),
        assert(illustrationThreshold > 0, 'Un seuil se compte en erreurs.');

  factory HintPolicy.fromJson(Map<String, dynamic> json) {
    return HintPolicy(
      syllablesThreshold: json['syllablesThreshold'] as int? ?? 1,
      illustrationThreshold: json['illustrationThreshold'] as int? ?? 5,
    );
  }

  final int syllablesThreshold;
  final int illustrationThreshold;

  /// Les aides acquises pour un mot ayant accumule [errorCount] erreurs.
  Set<Hint> hintsFor(int errorCount) {
    return <Hint>{
      if (errorCount >= syllablesThreshold) Hint.syllables,
      if (errorCount >= illustrationThreshold) Hint.illustration,
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'syllablesThreshold': syllablesThreshold,
      'illustrationThreshold': illustrationThreshold,
    };
  }
}
