import 'package:grisbie/domain/models/stage.dart';

/// Le message qui s'ouvre quand l'enfant a range tous les mots d'une boite.
///
/// **« Bravo ! » en titre, toujours** — une phrase qui revient a l'identique,
/// qu'un lecteur debutant reconnait sans la dechiffrer. Dessous, le texte que
/// l'auteur a ecrit pour ce trajet (`WordFamily.completionText`) : il dit ce
/// que l'enfant vient de faire, et ce qu'il peut faire maintenant — « Tu
/// peux prendre la voiture ».
///
/// **Rien n'est pre-ecrit** (decision de l'auteur) : le texte est de la
/// narration, obligatoire, et `validate()` signale son absence. Il ne manque
/// donc que dans un lieu inacheve que l'outil fait essayer : « Bravo ! »
/// s'affiche alors seul.
class CompletionMessage {
  const CompletionMessage({required this.title, this.body});

  /// Le titre, que l'auteur ne change pas.
  static const String bravo = 'Bravo !';

  final String title;

  /// Le texte de l'auteur, ou `null` dans un lieu inacheve.
  final String? body;

  /// Le message a montrer quand [familyId] vient d'etre complete, ou `null`.
  ///
  /// **« Autre chose » ne dit rien** (decision de l'auteur) : completer la
  /// liste du reste d'un tri unique n'ouvre aucun chemin, il n'y a rien a
  /// annoncer.
  static CompletionMessage? forFamily({
    required Stage stage,
    required String familyId,
  }) {
    final family = stage.findFamily(familyId);
    if (family == null || !family.leadsSomewhere) return null;

    final text = family.completionText?.trim();
    return CompletionMessage(
      title: bravo,
      body: text == null || text.isEmpty ? null : text,
    );
  }
}
