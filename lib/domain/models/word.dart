/// Un mot a lire et a classer.
///
/// Le decoupage syllabique est porte par le mot lui-meme : c'est une donnee de
/// contenu, jamais calculee par le code. Le francais n'a pas de regle de
/// syllabation assez sure pour etre automatisee sans risque, et une syllabe
/// fausse induirait l'enfant en erreur sur le point meme que le jeu cherche a
/// travailler.
class Word {
  const Word({
    required this.id,
    required this.text,
    required this.syllables,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      text: json['text'] as String,
      syllables: List<String>.unmodifiable(
        (json['syllables'] as List<dynamic>).cast<String>(),
      ),
    );
  }

  /// Identifiant stable, independant du texte affiche.
  final String id;

  /// Le mot tel que l'enfant le lit.
  final String text;

  /// Decoupage en syllabes, dans l'ordre : ['chaus', 'sure'].
  final List<String> syllables;

  Word copyWith({
    String? id,
    String? text,
    List<String>? syllables,
  }) {
    return Word(
      id: id ?? this.id,
      text: text ?? this.text,
      syllables: syllables ?? this.syllables,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'syllables': syllables,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Word && other.id == id && other.text == text;

  @override
  int get hashCode => Object.hash(id, text);

  @override
  String toString() => 'Word($id)';
}
