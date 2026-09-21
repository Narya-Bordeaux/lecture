/// Le recit d'un lieu.
///
/// **Un lieu raconte son arrivee, jamais son depart.** L'enfant y entre, lit ce
/// qui donne son sens a ce qui va lui etre demande, puis classe ses mots. Quand
/// il repart, c'est le lieu **suivant** qui raconte — son propre [onArrival].
///
/// Un recit de depart existait, et disait la meme chose deux fois : le contenu
/// livre faisait annoncer l'arrivee a la plage par le lieu qu'on quittait,
/// avant que la plage ne la raconte a son tour. La narration appartient a celui
/// qui accueille.
///
/// Un objet pour un seul champ, et c'est voulu : le concept se nomme, le format
/// de contenu garde sa forme (`"narrative": { "onArrival": … }`), et un second
/// moment aurait ou se poser le jour ou il se justifierait.
class Narrative {
  const Narrative({this.onArrival});

  factory Narrative.fromJson(Object? json) {
    // Tolere l'ancienne forme, ou le recit etait une simple chaine.
    if (json is String) return Narrative(onArrival: json);
    if (json is Map<String, dynamic>) {
      return Narrative(onArrival: json['onArrival'] as String?);
    }
    return const Narrative();
  }

  static const Narrative none = Narrative();

  /// Affiche en arrivant, avant que l'enfant ne classe quoi que ce soit.
  final String? onArrival;

  bool get isEmpty => onArrival == null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (onArrival != null) 'onArrival': onArrival,
    };
  }
}
