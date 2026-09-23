/// Un mot a lire et a classer.
///
/// Le mot est sa propre clef : le jeu est francophone et n'a pas vocation a
/// etre traduit. Un identifiant technique distinct de l'orthographe
/// n'ajouterait qu'un detour a l'ecriture du contenu — il faudrait savoir que
/// « arret » se nomme `bus_stop` pour l'employer dans une aventure.
///
/// Consequence assumee : deux mots de meme orthographe ne peuvent coexister.
/// Ils ne le pourraient pas de toute facon, l'enfant ne voyant que
/// l'orthographe a l'ecran.
///
/// **Le mot n'est plus que son orthographe.** Il portait son decoupage en
/// syllabes, qui ne servait qu'a l'aide affichee apres une erreur. L'aide a
/// ete retiree du jeu (0.33.0), et le decoupage avec elle : une donnee que
/// rien n'utilise finit fausse sans que personne ne le voie. Un contenu ecrit
/// avant se lit toujours — le champ `syllables` y est ignore.
class Word {
  const Word({required this.text});

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(text: json['text'] as String);
  }

  /// Le mot tel que l'enfant le lit, et la clef qui le designe partout.
  final String text;

  Map<String, dynamic> toJson() => <String, dynamic>{'text': text};

  @override
  bool operator ==(Object other) => other is Word && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'Word($text)';
}
