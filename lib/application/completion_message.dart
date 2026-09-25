import 'package:grisbie/domain/models/stage.dart';

/// Le message qui s'ouvre quand l'enfant a range tous les mots d'une boite.
///
/// **« Bravo ! » en titre, toujours** — une phrase qui revient a l'identique,
/// qu'un lecteur debutant reconnait sans la dechiffrer. Dessous, le texte que
/// l'auteur a ecrit pour ce trajet ; sinon un texte compose d'apres le lieu :
/// la boite rangee, le lieu ou mene le chemin, et l'autre choix s'il en
/// reste un.
///
/// Dart pur : dire s'il reste un chemin a ouvrir est une regle du jeu, et
/// l'outil d'auteur doit proposer exactement le texte que le jeu montrera.
class CompletionMessage {
  const CompletionMessage({required this.title, required this.body});

  /// Le titre, que l'auteur ne change pas.
  static const String bravo = 'Bravo !';

  final String title;
  final String body;

  /// Le message a montrer quand [familyId] vient d'etre complete, ou `null`.
  ///
  /// **« Autre chose » ne dit rien** (decision de l'auteur) : completer la
  /// liste du reste d'un tri unique n'ouvre aucun chemin, il n'y a rien a
  /// annoncer.
  ///
  /// [destinationNames] donne le nom de chaque lieu par son identifiant ; un
  /// lieu absent — l'outil fait essayer un lieu seul — fait parler du chemin.
  static CompletionMessage? forFamily({
    required Stage stage,
    required String familyId,
    required Set<String> completedFamilyIds,
    required Map<String, String> destinationNames,
  }) {
    final family = stage.findFamily(familyId);
    if (family == null || !family.leadsSomewhere) return null;

    final authored = family.completionText;
    if (authored != null && authored.trim().isNotEmpty) {
      return CompletionMessage(title: bravo, body: authored);
    }

    final otherPathsRemain = stage.families.any(
      (other) =>
          other.id != familyId &&
          other.leadsSomewhere &&
          !completedFamilyIds.contains(other.id),
    );
    return CompletionMessage(
      title: bravo,
      body: defaultText(
        familyLabel: family.label,
        destinationName: destinationNames[family.destinationStageId],
        otherPathsRemain: otherPathsRemain,
      ),
    );
  }

  /// Le texte que l'outil propose a l'auteur, pre-ecrit dans son champ.
  ///
  /// Il se lit comme si d'autres chemins restaient a ouvrir, quand le lieu en
  /// a plusieurs : c'est le cas de la premiere boite rangee, et le jeu retire
  /// de lui-meme cette fin quand il n'en reste plus.
  static String proposedFor({
    required Stage stage,
    required String familyId,
    required Map<String, String> destinationNames,
  }) {
    final family = stage.findFamily(familyId)!;
    final exits = stage.families.where((f) => f.leadsSomewhere).length;
    return defaultText(
      familyLabel: family.label,
      destinationName: destinationNames[family.destinationStageId],
      otherPathsRemain: exits > 1,
    );
  }

  /// Ce que l'outil enregistre d'un champ edite : rien si l'auteur a garde
  /// le texte propose, ou vide le champ.
  ///
  /// Garder le texte propose sans l'ecrire, c'est le laisser suivre les noms
  /// du trajet et du lieu, et la fin qui s'adapte aux chemins restants. Le
  /// figer dans le fichier le ferait mentir au premier renommage.
  static String? storedText(String edited, {required String proposed}) {
    final text = edited.trim();
    if (text.isEmpty || text == proposed.trim()) return null;
    return text;
  }

  /// Le texte compose d'apres le lieu.
  static String defaultText({
    required String familyLabel,
    String? destinationName,
    required bool otherPathsRemain,
  }) {
    final path = destinationName == null
        ? 'Tu peux suivre ce chemin'
        : 'Tu peux partir vers ${_lowercaseArticle(destinationName)}';
    final end = otherPathsRemain ? ', ou ouvrir un autre chemin.' : '.';
    // Espaces insecables dans les guillemets : « ne reste jamais seul en fin
    // de ligne, loin du mot qu'il ouvre.
    return 'Tu as rangé tous les mots «\u00A0$familyLabel\u00A0». $path$end';
  }

  /// « La gare » devient « la gare » au milieu d'une phrase ; « Paris »
  /// reste « Paris ». Seul l'article prend une minuscule.
  static String _lowercaseArticle(String name) {
    final match = _leadingArticle.firstMatch(name);
    if (match == null) return name;
    return match.group(0)!.toLowerCase() + name.substring(match.end);
  }

  static final RegExp _leadingArticle = RegExp(
    r"^(Le |La |Les |L'|L’|Un |Une |Des )",
  );
}
