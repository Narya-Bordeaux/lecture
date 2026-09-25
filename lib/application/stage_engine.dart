import 'dart:math';

import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';

/// Une direction ouverte : la famille completee et le lieu qu'elle dessert.
class AvailableDestination {
  const AvailableDestination({
    required this.familyId,
    required this.familyLabel,
    required this.stageId,
    this.departureLabel,
  });

  final String familyId;

  /// L'action ecrite sur le bouton, « Prendre la voiture ». Nulle dans un
  /// lieu inacheve que l'outil fait essayer : le jeu refuse ces lieux.
  final String? departureLabel;
  final String familyLabel;
  final String stageId;

  @override
  bool operator ==(Object other) =>
      other is AvailableDestination &&
      other.familyId == familyId &&
      other.stageId == stageId;

  @override
  int get hashCode => Object.hash(familyId, stageId);

  @override
  String toString() => 'AvailableDestination($familyId -> $stageId)';
}

/// Ce que produit une tentative de placement.
class PlacementResult {
  const PlacementResult({
    required this.accepted,
    this.completedFamilyId,
  });

  /// Vrai si le mot appartenait bien a cette famille.
  ///
  /// Un refus ne coute rien et n'ouvre rien : le mot reste a sa place, et
  /// l'enfant reessaie. Il n'y a plus d'aide qui se debloquerait a l'erreur.
  final bool accepted;

  /// La famille que ce placement vient de completer, s'il y en a une.
  final String? completedFamilyId;

  @override
  String toString() =>
      'PlacementResult(accepted: $accepted)';
}

/// L'etat d'une etape en cours, en lecture seule pour l'interface.
class StageState {
  StageState._(this._stage);

  final Stage _stage;

  final Map<String, String> _placements = <String, String>{};
  String? _departedTo;

  /// Les mots qui attendent leur tour, dans l'ordre ou ils apparaitront.
  final List<Word> _supply = <Word>[];

  /// Les mots deja poses dans leur famille.
  Set<String> get placedWordTexts => Set<String>.unmodifiable(_placements.keys);

  /// Ou chaque mot a ete pose : le mot vers l'identifiant de sa famille.
  Map<String, String> get placements => Map<String, String>.unmodifiable(
        _placements,
      );

  /// Les familles dont l'objectif est atteint.
  Set<String> get completedFamilyIds {
    return _stage.families
        .where(_isFamilyComplete)
        .map((family) => family.id)
        .toSet();
  }

  /// Combien de mots de cette famille ont ete classes.
  int placedCountIn(String familyId) {
    return _placements.values.where((id) => id == familyId).length;
  }

  /// Combien de mots attendent encore en reserve.
  int get remainingInSupply => _supply.length;

  /// Les directions ouvertes, parmi lesquelles l'enfant choisira de partir.
  ///
  /// Une famille qui ne mene nulle part en est exclue, meme complete : c'est
  /// le cas du classeur de rebut d'une enigme, ou l'enfant range ce qui ne
  /// repond pas a la question. Le remplir ne doit ouvrir aucun chemin.
  List<AvailableDestination> get availableDestinations {
    return _stage.families
        .where((family) => family.leadsSomewhere && _isFamilyComplete(family))
        .map(
          (family) => AvailableDestination(
            familyId: family.id,
            familyLabel: family.label,
            stageId: family.destinationStageId!,
            departureLabel: family.departureLabel,
          ),
        )
        .toList(growable: false);
  }

  /// L'etape ne se termine pas toute seule : elle attend que l'enfant parte.
  bool get isFinished => _departedTo != null;

  /// L'etape vers laquelle l'enfant est parti, nulle tant qu'il est la.
  String? get departedTo => _departedTo;

  bool _isFamilyComplete(WordFamily family) {
    return placedCountIn(family.id) >= family.requiredCount;
  }
}

/// Le moteur d'une etape : il applique les regles, il n'affiche rien.
///
/// Volontairement sans dependance a Flutter, pour rester testable en Dart pur
/// et reutilisable dans un autre contexte d'affichage.
class StageEngine {
  /// Ouvre l'etape, ce qui **tire les mots de la partie**.
  ///
  /// Les listes d'un lieu sont reutilisables et plus grandes que la partie :
  /// `Stage.drawnWith` en retire d'abord les mots communs a plusieurs listes —
  /// ils seraient ambigus — puis en tire le nombre demande. Le moteur ne joue
  /// donc jamais l'etape declaree, mais l'etape **tiree**, et deux entrees
  /// dans le meme lieu ne donnent pas les memes mots.
  ///
  /// Le tirage a lieu ici, et non chez l'appelant : l'interface n'a pas a
  /// connaitre une regle de jeu, et le [Random] injecte est deja la.
  factory StageEngine({
    required Stage stage,
    Random? random,
  }) {
    final draw = random ?? Random();
    return StageEngine._(stage.drawnWith(draw), draw);
  }

  StageEngine._(Stage stage, this._random)
      : _stage = stage,
        state = StageState._(stage) {
    _fillInitialSlots();
  }

  /// L'etape telle qu'elle se joue : listes reduites au tirage.
  final Stage _stage;
  final Random _random;

  /// L'etat courant, expose en lecture a l'interface.
  final StageState state;

  /// Les emplacements affiches. Un emplacement vide vaut null : la reserve est
  /// epuisee et la grille se vide sans que les mots restants ne bougent.
  final List<Word?> _slots = <Word?>[];

  Stage get stage => _stage;

  /// Les mots proposes en ce moment, emplacement par emplacement.
  List<Word?> get visibleWords => List<Word?>.unmodifiable(_slots);

  /// Constitue la reserve melangee, puis garnit les emplacements.
  ///
  /// Le melange passe par le [Random] injecte : a graine fixee, la suite des
  /// mots est reproductible, ce qui rend les tests deterministes.
  void _fillInitialSlots() {
    state._supply.addAll(List<Word>.of(_stage.words)..shuffle(_random));

    final slotCount = _stage.visibleWordCount.clamp(1, _stage.words.length);
    for (var slot = 0; slot < slotCount; slot++) {
      _slots.add(state._supply.isEmpty ? null : state._supply.removeAt(0));
    }
  }

  /// Tente de poser [wordText] dans [familyId].
  ///
  /// Leve une [ArgumentError] si l'un des identifiants est inconnu ou si le mot
  /// est deja place, et une [StateError] si l'etape est terminee : ce sont des
  /// erreurs de programmation de l'interface, pas des coups de l'enfant.
  PlacementResult placeWord({
    required String wordText,
    required String familyId,
  }) {
    if (state.isFinished) {
      throw StateError(
        'L\'etape "${_stage.id}" est terminee, plus aucun placement possible.',
      );
    }

    final word = _stage.findWord(wordText);
    if (word == null) {
      throw ArgumentError.value(
        wordText,
        'wordText',
        'Mot absent de l\'etape "${_stage.id}"',
      );
    }

    final family = _stage.findFamily(familyId);
    if (family == null) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'Famille absente de l\'etape "${_stage.id}"',
      );
    }

    if (state._placements.containsKey(wordText)) {
      throw ArgumentError.value(
        wordText,
        'wordText',
        'Mot deja place dans la famille "${state._placements[wordText]}"',
      );
    }

    if (!family.accepts(wordText)) {
      return const PlacementResult(accepted: false);
    }

    state._placements[wordText] = familyId;
    _refillSlotOf(wordText);

    return PlacementResult(
      accepted: true,
      completedFamilyId: state._isFamilyComplete(family) ? family.id : null,
    );
  }

  /// Remplace le mot qui vient d'etre classe par le suivant de la reserve.
  ///
  /// Le nouveau mot reprend exactement l'emplacement libere, et lui seul : les
  /// autres mots ne bougent pas, pour que l'enfant ne perde pas des yeux celui
  /// qu'il etait en train de dechiffrer.
  void _refillSlotOf(String wordText) {
    final slot = _slots.indexWhere((word) => word?.text == wordText);
    if (slot < 0) return;

    _slots[slot] = state._supply.isEmpty ? null : state._supply.removeAt(0);
  }

  /// Fait partir le chat vers [stageId], qui doit etre une destination ouverte.
  ///
  /// C'est le seul moyen de terminer une etape : completer une famille ne
  /// suffit pas, l'enfant garde la main sur le moment du depart.
  void departTo(String stageId) {
    if (state.isFinished) {
      throw StateError('L\'etape "${_stage.id}" est deja terminee.');
    }

    final isAvailable = state.availableDestinations.any(
      (destination) => destination.stageId == stageId,
    );
    if (!isAvailable) {
      throw StateError(
        'La destination "$stageId" n\'est pas ouverte : sa famille n\'est pas '
        'complete.',
      );
    }

    state._departedTo = stageId;
  }
}
