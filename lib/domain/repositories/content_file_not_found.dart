/// Le fichier de contenu demande n'existe pas.
///
/// **A distinguer de « je n'ai pas pu le lire ».** Une absence est un etat
/// normal et interpretable — un dossier de travail encore vide, une aventure
/// qu'on n'a jamais enregistree — alors qu'un refus du depot, une panne de
/// reseau ou un blocage du navigateur sont des pannes, qui doivent se voir.
///
/// La distinction existe pour `FallbackContentSource`, qui se replie sur le
/// contenu livre : confondre les deux lui faisait servir en silence une
/// version perimee, et l'auteur cherchait alors dans la liste une aventure
/// qu'il venait pourtant d'enregistrer.
class ContentFileNotFound implements Exception {
  const ContentFileNotFound(this.path, {this.cause});

  /// Le chemin demande, relatif au dossier du contenu.
  final String path;

  /// Ce que la plateforme a rendu, garde pour le diagnostic.
  final Object? cause;

  @override
  String toString() => 'Fichier de contenu absent : "$path".';
}
