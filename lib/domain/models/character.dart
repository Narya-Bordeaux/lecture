/// Un personnage que le chat rencontre en chemin.
///
/// Le personnage existe independamment des etapes ou il apparait : il peut
/// revenir dans plusieurs aventures. Seule sa replique depend de la scene, et
/// vit donc dans l'etape, pas ici.
class Character {
  const Character({
    required this.id,
    required this.name,
    this.portraitAsset,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      portraitAsset: json['portrait'] as String?,
    );
  }

  final String id;

  /// Nom affiche a l'enfant, par exemple « Le pecheur ».
  final String name;

  /// Portrait, absent tant que le dessin n'existe pas.
  final String? portraitAsset;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      if (portraitAsset != null) 'portrait': portraitAsset,
    };
  }

  @override
  String toString() => 'Character($id)';
}

/// La rencontre d'un personnage dans une etape : qui parle, et ce qu'il dit.
class Encounter {
  const Encounter({required this.character, required this.line});

  final Character character;

  /// Ce que le personnage demande a l'enfant, propre a cette etape.
  final String line;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': character.id, 'line': line};
  }

  @override
  String toString() => 'Encounter(${character.id})';
}
