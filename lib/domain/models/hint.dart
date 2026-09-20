/// Les deux aides a la lecture proposees pendant le classement.
///
/// L'ordre de declaration suit l'ordre pedagogique : le decoupage aide a
/// dechiffrer sans livrer le sens, l'illustration donne le sens et donc
/// presque la reponse.
enum Hint {
  /// Montre le mot decoupe en syllabes.
  syllables,

  /// Montre une image de ce que le mot designe.
  illustration;

  static Hint fromName(String name) {
    return Hint.values.firstWhere(
      (hint) => hint.name == name,
      orElse: () => throw ArgumentError.value(name, 'name', 'Aide inconnue'),
    );
  }
}
