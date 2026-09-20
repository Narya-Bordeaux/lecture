/// Les deux moments de recit d'une etape.
///
/// [onArrival] s'affiche en entrant dans le lieu, avant de jouer : il donne son
/// sens a ce qui va etre demande. [onCompletion] accompagne le depart, et
/// repond a la specification, qui veut « un court episode de l'histoire apres
/// chaque avancee ».
///
/// Les deux sont facultatifs : une etape peut se passer de recit.
class Narrative {
  const Narrative({this.onArrival, this.onCompletion});

  factory Narrative.fromJson(Object? json) {
    // Tolere l'ancienne forme, ou le recit etait une simple chaine.
    if (json is String) return Narrative(onArrival: json);
    if (json is Map<String, dynamic>) {
      return Narrative(
        onArrival: json['onArrival'] as String?,
        onCompletion: json['onCompletion'] as String?,
      );
    }
    return const Narrative();
  }

  static const Narrative none = Narrative();

  /// Affiche en arrivant, avant que l'enfant ne classe quoi que ce soit.
  final String? onArrival;

  /// Affiche au moment de quitter le lieu.
  final String? onCompletion;

  bool get isEmpty => onArrival == null && onCompletion == null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (onArrival != null) 'onArrival': onArrival,
      if (onCompletion != null) 'onCompletion': onCompletion,
    };
  }
}
