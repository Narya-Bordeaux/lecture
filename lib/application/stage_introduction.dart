import 'package:grisbie/domain/models/stage.dart';

/// Les temps de la mise en place d'un lieu, dans l'ordre ou l'enfant les vit.
enum IntroductionStep {
  /// Le decor seul, un bref instant.
  background,

  /// L'enonce, au milieu de l'ecran, que l'enfant ferme d'une fleche.
  statement,

  /// Le cartouche est la ; les boites se presentent une a une, au centre,
  /// et vont se ranger a leur place quand l'enfant les touche.
  families,

  /// Tout est en place : les mots se deplacent.
  playing,
}

/// La mise en place d'un lieu, avant que l'enfant ne classe quoi que ce soit.
///
/// Decor seul, puis l'enonce, puis le cartouche des mots et chaque boite de
/// rangement presentee une a une : l'enfant decouvre ce qu'on lui demande
/// avant d'avoir a le faire. **Tant que la derniere boite n'est pas rangee,
/// les mots se lisent mais ne bougent pas.**
///
/// Dart pur, comme le moteur : l'ordre des boites et ce qui se saute sont des
/// regles du jeu, pas des choix d'affichage. L'interface ne fait que montrer
/// l'etat, et appeler [advance] quand l'enfant a fini un temps.
///
/// Immuable : chaque pas rend un nouvel etat.
class StageIntroduction {
  const StageIntroduction._({
    required this.step,
    required this.familyOrder,
    required this.hasStatement,
    required this.placedCount,
  });

  /// La mise en place complete d'un lieu, a son tout debut.
  ///
  /// Les boites se presentent **dans l'ordre de creation** — celui du
  /// fichier —, **« autre chose » toujours en dernier** : le theme d'un tri
  /// unique donne son sens au reste, et doit etre connu avant lui. Une boite
  /// sans place sur le decor n'est pas presentee : elle n'aurait nulle part
  /// ou aller.
  factory StageIntroduction.forStage(Stage stage) {
    final statement = stage.narrative.onArrival;
    return StageIntroduction._(
      step: IntroductionStep.background,
      familyOrder: _orderOf(stage),
      hasStatement: statement != null && statement.trim().isNotEmpty,
      placedCount: 0,
    );
  }

  /// Aucune mise en place : le jeu est ouvert d'emblee, toutes les boites
  /// rangees. C'est l'apercu de l'outil de calage.
  factory StageIntroduction.skipped(Stage stage) {
    final order = _orderOf(stage);
    return StageIntroduction._(
      step: IntroductionStep.playing,
      familyOrder: order,
      hasStatement: false,
      placedCount: order.length,
    );
  }

  /// Combien de temps le decor se montre seul, avant l'enonce.
  ///
  /// Decision de l'auteur : un quart de seconde, juste le temps de voir ou
  /// l'on arrive.
  static const Duration backgroundOnlyDuration = Duration(milliseconds: 250);

  final IntroductionStep step;

  /// Les identifiants des boites, dans l'ordre ou elles se presentent.
  final List<String> familyOrder;

  final bool hasStatement;

  /// Combien de boites sont deja rangees a leur place.
  final int placedCount;

  /// Le cartouche paraît une fois l'enonce ferme, et ne repart plus.
  bool get isTrayVisible =>
      step == IntroductionStep.families || step == IntroductionStep.playing;

  /// Les mots ne se deplacent qu'une fois toutes les boites rangees.
  bool get canMoveWords => step == IntroductionStep.playing;

  /// La boite presentee au centre de l'ecran, ou `null` hors de ce temps.
  String? get presentedFamilyId =>
      step == IntroductionStep.families ? familyOrder[placedCount] : null;

  /// Vrai si la boite est deja a sa place sur le decor.
  ///
  /// Une boite que la mise en place ne presente pas — faute de place sur le
  /// decor — n'est « rangee » qu'une fois le jeu ouvert.
  bool isFamilyPlaced(String familyId) {
    if (step == IntroductionStep.playing) return true;
    final position = familyOrder.indexOf(familyId);
    return position >= 0 && position < placedCount;
  }

  /// Passe au temps suivant, en sautant ce qui n'a rien a montrer.
  StageIntroduction advance() {
    return switch (step) {
      IntroductionStep.background => hasStatement
          ? _with(step: IntroductionStep.statement)
          : _afterStatement(),
      IntroductionStep.statement => _afterStatement(),
      IntroductionStep.families => placedCount + 1 < familyOrder.length
          ? _with(placedCount: placedCount + 1)
          : _with(
              step: IntroductionStep.playing,
              placedCount: familyOrder.length,
            ),
      IntroductionStep.playing =>
        throw StateError('La mise en place est terminee : le jeu est ouvert.'),
    };
  }

  StageIntroduction _afterStatement() {
    return _with(
      step: familyOrder.isEmpty
          ? IntroductionStep.playing
          : IntroductionStep.families,
    );
  }

  StageIntroduction _with({IntroductionStep? step, int? placedCount}) {
    return StageIntroduction._(
      step: step ?? this.step,
      familyOrder: familyOrder,
      hasStatement: hasStatement,
      placedCount: placedCount ?? this.placedCount,
    );
  }

  static List<String> _orderOf(Stage stage) {
    final placeable = stage.families.where((family) => family.area != null);
    return List<String>.unmodifiable(<String>[
      for (final family in placeable)
        if (family.leadsSomewhere) family.id,
      // La liste du reste ne mene nulle part : elle passe apres le theme.
      for (final family in placeable)
        if (!family.leadsSomewhere) family.id,
    ]);
  }
}
