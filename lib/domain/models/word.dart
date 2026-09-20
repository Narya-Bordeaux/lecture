/// Un mot a lire et a classer.
///
/// Le decoupage syllabique et l'illustration sont portes par le mot lui-meme :
/// ce sont des donnees de contenu, jamais calculees par le code. Le francais
/// n'a pas de regle de syllabation assez sure pour etre automatisee sans
/// risque, et une syllabe fausse induirait l'enfant en erreur sur le point
/// meme que le jeu cherche a travailler.
class Word {
  const Word({
    required this.id,
    required this.text,
    required this.syllables,
    this.illustrationAsset,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      text: json['text'] as String,
      syllables: List<String>.unmodifiable(
        (json['syllables'] as List<dynamic>).cast<String>(),
      ),
      illustrationAsset: json['illustrationAsset'] as String?,
    );
  }

  /// Identifiant stable, independant du texte affiche.
  final String id;

  /// Le mot tel que l'enfant le lit.
  final String text;

  /// Decoupage en syllabes, dans l'ordre : ['chau', 'ssure'].
  final List<String> syllables;

  /// Chemin de l'illustration, absent tant que le dessin n'existe pas.
  final String? illustrationAsset;

  /// Vrai si l'illustration peut reellement etre montree a l'enfant.
  bool get hasIllustration => illustrationAsset != null;

  Word copyWith({
    String? id,
    String? text,
    List<String>? syllables,
    String? illustrationAsset,
  }) {
    return Word(
      id: id ?? this.id,
      text: text ?? this.text,
      syllables: syllables ?? this.syllables,
      illustrationAsset: illustrationAsset ?? this.illustrationAsset,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'syllables': syllables,
      if (illustrationAsset != null) 'illustrationAsset': illustrationAsset,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Word &&
      other.id == id &&
      other.text == text &&
      other.illustrationAsset == illustrationAsset;

  @override
  int get hashCode => Object.hash(id, text, illustrationAsset);

  @override
  String toString() => 'Word($id)';
}
