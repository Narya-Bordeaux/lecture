/// Les aides a la lecture proposees pendant le classement.
///
/// Il n'y en a qu'une. L'illustration du mot, un temps prevue, a ete ecartee :
/// avec trois familles seulement, les possibilites se reduisent d'elles-memes a
/// mesure que les categories se remplissent, et un enfant qui a oublie le sens
/// d'un mot finit par n'avoir plus qu'un choix. Montrer l'image en plus
/// reviendrait a donner la reponse.
enum Hint {
  /// Montre le mot decoupe en syllabes.
  syllables;

  static Hint fromName(String name) {
    return Hint.values.firstWhere(
      (hint) => hint.name == name,
      orElse: () => throw ArgumentError.value(name, 'name', 'Aide inconnue'),
    );
  }
}
