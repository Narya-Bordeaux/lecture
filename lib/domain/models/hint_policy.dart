import 'package:reading_game/domain/models/hint.dart';

/// A partir de combien d'erreurs sur un meme mot l'aide se debloque.
///
/// La valeur par defaut est celle de la specification : des la premiere erreur.
/// Le decoupage syllabique aide a dechiffrer sans livrer le sens, il peut donc
/// arriver tot sans priver l'enfant du travail de comprehension.
///
/// La classe est injectable pour que les niveaux puissent un jour faire varier
/// ce seuil sans toucher au moteur.
class HintPolicy {
  const HintPolicy({this.syllablesThreshold = 1})
      : assert(syllablesThreshold > 0, 'Un seuil se compte en erreurs.');

  factory HintPolicy.fromJson(Map<String, dynamic> json) {
    return HintPolicy(
      syllablesThreshold: json['syllablesThreshold'] as int? ?? 1,
    );
  }

  final int syllablesThreshold;

  /// Les aides acquises pour un mot ayant accumule [errorCount] erreurs.
  Set<Hint> hintsFor(int errorCount) {
    return <Hint>{
      if (errorCount >= syllablesThreshold) Hint.syllables,
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'syllablesThreshold': syllablesThreshold};
  }
}
