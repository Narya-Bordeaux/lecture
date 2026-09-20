import 'dart:math';

import 'package:reading_game/domain/models/hint.dart';
import 'package:reading_game/domain/models/hint_policy.dart';
import 'package:reading_game/domain/models/stage.dart';
import 'package:reading_game/domain/models/word.dart';
import 'package:reading_game/domain/models/word_family.dart';

/// Une direction ouverte : la famille completee et le lieu qu'elle dessert.
class AvailableDestination {
  const AvailableDestination({
    required this.familyId,
    required this.familyLabel,
    required this.stageId,
  });

  final String familyId;
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
    required this.unlockedHints,
    this.completedFamilyId,
  });

  /// Vrai si le mot appartenait bien a cette famille.
  final bool accepted;

  /// Les aides debloquees par cette tentative precisement.
  ///
  /// Vide si aucune aide nouvelle : l'interface s'en sert pour n'annoncer une
  /// aide qu'au moment ou elle apparait.
  final Set<Hint> unlockedHints;

  /// La famille que ce placement vient de completer, s'il y en a une.
  final String? completedFamilyId;

  @override
  String toString() =>
      'PlacementResult(accepted: $accepted, hints: $unlockedHints)';
}

/// L'etat d'une etape en cours, en lecture seule pour l'interface.
class StageState {
  StageState._(this._stage, this._hintPolicy);

  final Stage _stage;
  final HintPolicy _hintPolicy;

  final Map<String, String> _placements = <String, String>{};
  final Map<String, int> _errorCounts = <String, int>{};
  final Map<String, Set<Hint>> _requestedHints = <String, Set<Hint>>{};
  String? _departedTo;

  /// Les mots deja poses dans leur famille.
  Set<String> get placedWordIds => Set<String>.unmodifiable(_placements.keys);

  /// Ou chaque mot a ete pose : identifiant de mot vers identifiant de famille.
  Map<String, String> get placements => Map<String, String>.unmodifiable(
        _placements,
      );

  /// Nombre d'erreurs commises sur ce mot depuis le debut de l'etape.
  int errorCountFor(String wordId) => _errorCounts[wordId] ?? 0;

  /// Les aides disponibles sur ce mot, qu'elles aient ete debloquees par les
  /// erreurs ou demandees par l'enfant.
  Set<Hint> hintsFor(String wordId) {
    return <Hint>{
      ..._hintPolicy.hintsFor(errorCountFor(wordId)),
      ...?_requestedHints[wordId],
    };
  }

  /// Les familles dont tous les mots ont ete places.
  Set<String> get completedFamilyIds {
    return _stage.families
        .where(_isFamilyComplete)
        .map((family) => family.id)
        .toSet();
  }

  /// Les directions ouvertes, parmi lesquelles l'enfant choisira de partir.
  List<AvailableDestination> get availableDestinations {
    return _stage.families
        .where(_isFamilyComplete)
        .map(
          (family) => AvailableDestination(
            familyId: family.id,
            familyLabel: family.label,
            stageId: family.destinationStageId,
          ),
        )
        .toList(growable: false);
  }

  /// L'etape ne se termine pas toute seule : elle attend que l'enfant parte.
  bool get isFinished => _departedTo != null;

  /// L'etape vers laquelle l'enfant est parti, nulle tant qu'il est la.
  String? get departedTo => _departedTo;

  bool _isFamilyComplete(WordFamily family) {
    return family.wordIds.every(
      (wordId) => _placements[wordId] == family.id,
    );
  }
}

/// Le moteur d'une etape : il applique les regles, il n'affiche rien.
///
/// Volontairement sans dependance a Flutter, pour rester testable en Dart pur
/// et reutilisable dans un autre contexte d'affichage.
class StageEngine {
  StageEngine({
    required Stage stage,
    HintPolicy hintPolicy = const HintPolicy(),
    Random? random,
  })  : _stage = stage,
        _random = random ?? Random(),
        state = StageState._(stage, hintPolicy);

  final Stage _stage;
  final Random _random;

  /// L'etat courant, expose en lecture a l'interface.
  final StageState state;

  Stage get stage => _stage;

  /// Les mots dans l'ordre ou les presenter, melange une fois pour l'etape.
  ///
  /// Le melange passe par le [Random] injecte : a graine fixee, l'ordre est
  /// reproductible, ce qui rend les tests deterministes.
  late final List<Word> shuffledWords = List<Word>.unmodifiable(
    List<Word>.of(_stage.words)..shuffle(_random),
  );

  /// Tente de poser [wordId] dans [familyId].
  ///
  /// Leve une [ArgumentError] si l'un des identifiants est inconnu ou si le mot
  /// est deja place, et une [StateError] si l'etape est terminee : ce sont des
  /// erreurs de programmation de l'interface, pas des coups de l'enfant.
  PlacementResult placeWord({
    required String wordId,
    required String familyId,
  }) {
    if (state.isFinished) {
      throw StateError(
        'L\'etape "${_stage.id}" est terminee, plus aucun placement possible.',
      );
    }

    final word = _stage.findWord(wordId);
    if (word == null) {
      throw ArgumentError.value(
        wordId,
        'wordId',
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

    if (state._placements.containsKey(wordId)) {
      throw ArgumentError.value(
        wordId,
        'wordId',
        'Mot deja place dans la famille "${state._placements[wordId]}"',
      );
    }

    if (!family.accepts(wordId)) {
      return _rejectPlacement(wordId);
    }

    state._placements[wordId] = familyId;
    return PlacementResult(
      accepted: true,
      unlockedHints: const <Hint>{},
      completedFamilyId: state._isFamilyComplete(family) ? family.id : null,
    );
  }

  /// Comptabilise l'erreur et retourne les aides qu'elle fait apparaitre.
  PlacementResult _rejectPlacement(String wordId) {
    final hintsBefore = state.hintsFor(wordId);
    state._errorCounts[wordId] = state.errorCountFor(wordId) + 1;
    final hintsAfter = state.hintsFor(wordId);

    return PlacementResult(
      accepted: false,
      unlockedHints: hintsAfter.difference(hintsBefore),
    );
  }

  /// Rend une aide disponible a la demande de l'enfant, sans erreur commise.
  void requestHint({required String wordId, required Hint hint}) {
    if (_stage.findWord(wordId) == null) {
      throw ArgumentError.value(
        wordId,
        'wordId',
        'Mot absent de l\'etape "${_stage.id}"',
      );
    }
    state._requestedHints.putIfAbsent(wordId, () => <Hint>{}).add(hint);
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
