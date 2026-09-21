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
/// Le decoupage est porte par le mot lui-meme : c'est une donnee de contenu,
/// jamais calculee par le code. Le francais n'a pas de regle de syllabation
/// assez sure pour etre automatisee, et une coupe fausse induirait l'enfant en
/// erreur sur le point meme que le jeu cherche a travailler.
class Word {
  const Word({
    required this.text,
    required this.syllables,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      text: json['text'] as String,
      syllables: List<String>.unmodifiable(
        (json['syllables'] as List<dynamic>).cast<String>(),
      ),
    );
  }

  /// Le mot tel que l'enfant le lit, et la clef qui le designe partout.
  final String text;

  /// Le decoupage, dans l'ordre : ['chau', 'ssure'].
  ///
  /// Il suit les sons et non la coupure graphique academique — « a », « rê »
  /// pour « arret ». Il peut donc s'ecarter de l'orthographe : c'est un choix
  /// pedagogique, que le code laisse a l'auteur du contenu.
  final List<String> syllables;

  Word copyWith({
    String? text,
    List<String>? syllables,
  }) {
    return Word(
      text: text ?? this.text,
      syllables: syllables ?? this.syllables,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'text': text,
      'syllables': syllables,
    };
  }

  @override
  bool operator ==(Object other) => other is Word && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'Word($text)';
}
