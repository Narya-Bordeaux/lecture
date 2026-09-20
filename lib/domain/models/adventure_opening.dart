/// L'ecran qui ouvre une aventure : un titre, une illustration, un texte.
///
/// Ce n'est pas une etape — il n'y a rien a classer — mais la page de garde de
/// la journee qui commence. Elle appartient donc a l'aventure, pas a un lieu.
///
/// Sa mise en page differe volontairement de celle des moments de recit : le
/// titre annonce, l'image occupe la largeur, le texte se lit dessous. C'est un
/// seuil, pas une transition.
class AdventureOpening {
  const AdventureOpening({required this.text, this.title, this.imageAsset});

  factory AdventureOpening.fromJson(Map<String, dynamic> json) {
    return AdventureOpening(
      title: json['title'] as String?,
      imageAsset: json['image'] as String?,
      text: json['text'] as String? ?? '',
    );
  }

  /// Le titre affiche en haut. Absent, celui de l'aventure prend sa place :
  /// une aventure n'a pas a repeter son nom pour l'annoncer.
  final String? title;

  /// L'illustration d'ouverture, souvent horizontale, montree en entier.
  final String? imageAsset;

  /// Ce que l'on raconte avant de partir.
  final String text;

  /// Le titre a montrer, celui de l'aventure servant de repli.
  String titleOr(String adventureTitle) => title ?? adventureTitle;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (title != null) 'title': title,
      if (imageAsset != null) 'image': imageAsset,
      'text': text,
    };
  }
}
