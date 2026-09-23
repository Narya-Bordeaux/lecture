import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word_family.dart';

/// Le lettrage positionnel d'une aventure, tel qu'il se lit a l'auteur.
///
/// Reprend la forme du croquis papier : un point, puis les trajets qui en
/// partent, chacun menant a un point qui se deploie a son tour plus bas.
///
/// **Le lettrage ne se stocke jamais.** Il se recalcule a chaque affichage, et
/// il bouge : inserer un trajet avant un autre fait passer `B2` en `B3`. C'est
/// un excellent reperage a l'ecran et un tres mauvais identifiant — les vrais
/// identifiants restent francais, explicites et choisis par l'auteur.
class AdventureOutline {
  const AdventureOutline._({
    required this.blocks,
    required Map<String, String> lettersByStageId,
    required this.detachedStageIds,
  }) : _letters = lettersByStageId;

  /// Calcule le lettrage d'une aventure, meme inachevee.
  ///
  /// L'outil d'auteur travaille sur des brouillons : destinations annoncees
  /// avant leur lieu, lieux pas encore relies, cycles laisses en chemin. Rien
  /// de tout cela ne doit empecher l'affichage — sans quoi l'auteur perdrait de
  /// vue ce qu'il est en train d'ecrire au moment ou il en a le plus besoin.
  factory AdventureOutline.of(Adventure adventure) {
    final letters = <String, String>{};
    final blocks = <OutlineBlock>[];
    final detached = <String>[];

    // Chaque point qui se deploie consomme la lettre suivante pour le groupe
    // de ses arrivees. C'est la regle du croquis : B1 donne C, B2 donne D.
    //
    // Le depart porte « A » a lui seul, sans numero : il consomme donc la
    // premiere lettre, et le groupe de ses arrivees commence a « B ».
    var nextGroup = 1;

    void walkFrom(String rootStageId) {
      final queue = <String>[rootStageId];

      while (queue.isNotEmpty) {
        final stageId = queue.removeAt(0);
        final stage = adventure.findStage(stageId);
        if (stage == null) continue;

        // Les arrivees encore sans lettre, dans l'ordre des trajets.
        final newcomers = <String>[];
        for (final family in stage.families) {
          final destination = family.destinationStageId;
          if (destination == null) continue;
          if (letters.containsKey(destination)) continue;
          if (adventure.findStage(destination) == null) continue;
          if (newcomers.contains(destination)) continue;
          newcomers.add(destination);
        }

        // Un point dont toutes les arrivees sont deja lettrees ne consomme pas
        // de lettre : elle resterait inemployee dans la liste.
        if (newcomers.isNotEmpty) {
          final group = _groupLetter(nextGroup++);
          for (var index = 0; index < newcomers.length; index++) {
            letters[newcomers[index]] = '$group${index + 1}';
          }
          queue.addAll(newcomers);
        }

        // **Tout lieu a son bloc**, meme sans trajet. Un lieu qu'on vient de
        // creer n'en a pas encore : ne pas l'afficher le rendrait invisible et
        // impossible a prolonger, ce qui est precisement ce qu'on vient
        // d'ajouter un trajet pour faire.
        blocks.add(OutlineBlock(
          stageId: stageId,
          letter: letters[stageId]!,
          locationName: stage.locationName,
          hasNarrative: stage.narrative.onArrival != null,
          nature: stage.nature,
          canBeTried: stage.canBeTriedAlone,
          trips: List<OutlineTrip>.unmodifiable(
            stage.families
                .map((family) => _tripOf(stage, family, letters, adventure)),
          ),
        ));
      }
    }

    letters[adventure.startStageId] = 'A';
    walkFrom(adventure.startStageId);

    // Un lieu qu'aucun chemin n'atteint doit rester visible : sinon un lieu
    // cree puis oublie disparaitrait de l'ecran, et l'auteur ne pourrait plus
    // le relier. Chacun devient une racine a son tour.
    for (final stageId in adventure.stages.keys) {
      if (letters.containsKey(stageId)) continue;
      detached.add(stageId);
      letters[stageId] = _groupLetter(nextGroup++);
      walkFrom(stageId);
    }

    return AdventureOutline._(
      blocks: List<OutlineBlock>.unmodifiable(blocks),
      lettersByStageId: Map<String, String>.unmodifiable(letters),
      detachedStageIds: List<String>.unmodifiable(detached),
    );
  }

  static OutlineTrip _tripOf(
    Stage stage,
    WordFamily family,
    Map<String, String> letters,
    Adventure adventure,
  ) {
    final destination = family.destinationStageId;
    final arrival = destination == null ? null : adventure.findStage(destination);

    return OutlineTrip(
      familyId: family.id,
      label: family.label,
      destinationStageId: destination,
      destinationName: arrival?.locationName,
      destinationLetter: destination == null ? null : letters[destination],
      leadsToSingleSort: arrival?.isSingleSort ?? false,
      leadsToEnding: arrival?.isEnding ?? false,
      supply: family.lists.isEmpty ? null : stage.supplyOf(family),
    );
  }

  /// La lettre d'un groupe : A, B, … Z, puis AA, AB, …
  ///
  /// Un parcours tres ramifie depasse vingt-six groupes, et deux groupes
  /// homonymes rendraient deux lieux indiscernables a l'ecran.
  static String _groupLetter(int index) {
    var remaining = index;
    final letter = StringBuffer();
    do {
      letter.write(String.fromCharCode(65 + remaining % 26));
      remaining = remaining ~/ 26 - 1;
    } while (remaining >= 0);

    return String.fromCharCodes(letter.toString().codeUnits.reversed);
  }

  final Map<String, String> _letters;

  /// Les points du parcours, dans l'ordre de lecture du croquis.
  ///
  /// **Tout lieu y figure**, fin comprise : une fin n'a rien a deployer, mais
  /// elle porte un ecran, une illustration et un texte d'arrivee, et l'auteur
  /// doit la voir. Un lieu atteint par deux chemins n'y figure qu'une fois.
  final List<OutlineBlock> blocks;

  /// Les lieux qu'aucun chemin n'atteint, a montrer a part.
  final List<String> detachedStageIds;

  /// La lettre d'un lieu, ou `null` s'il n'existe pas encore.
  String? letterOf(String stageId) => _letters[stageId];
}

/// Un point du parcours et les trajets qui en partent.
class OutlineBlock {
  const OutlineBlock({
    required this.stageId,
    required this.letter,
    required this.locationName,
    required this.hasNarrative,
    required this.nature,
    required this.canBeTried,
    required this.trips,
  });

  final String stageId;

  /// Son reperage a l'ecran : « A », « B1 », « C2 ».
  final String letter;

  final String locationName;

  /// La case du croquis : le recit d'arrivee est-il ecrit ?
  ///
  /// Un lieu ne raconte pas son depart — c'est celui d'apres qui raconte.
  final bool hasNarrative;

  /// Ce que l'enfant fait ici — ou `undefined`, tant que l'auteur ne l'a pas
  /// dit. C'est ce qui decide de ce que la carte propose.
  final StageNature nature;

  /// Vrai si le lieu se joue seul : la carte propose alors de l'essayer.
  final bool canBeTried;

  /// Vrai si l'enfant y trie entre une liste et son complement.
  ///
  /// Un tel lieu n'a qu'une sortie : l'ecran n'en propose donc pas davantage.
  bool get isSingleSort => nature == StageNature.singleSort;

  /// Vrai si le lieu clot le parcours. Il n'a alors aucun trajet.
  bool get isEnding => nature == StageNature.ending;

  /// Les trajets qui partent d'ici. Vide pour un lieu pas encore ecrit, comme
  /// pour une fin.
  final List<OutlineTrip> trips;
}

/// Un trajet qui part d'un point.
///
/// C'est une famille de mots portant une destination. La **liste du reste**
/// d'un tri unique en est une qui ne mene nulle part : il faut la voir, sans
/// qu'elle ouvre de chemin.
class OutlineTrip {
  const OutlineTrip({
    required this.familyId,
    required this.label,
    required this.destinationStageId,
    required this.destinationName,
    required this.destinationLetter,
    required this.leadsToSingleSort,
    required this.leadsToEnding,
    this.supply,
  });

  final String familyId;

  /// Ce que l'enfant lit sur la zone de depot : « En bus ».
  final String label;

  /// Le lieu atteint.
  ///
  /// Nul pour la **liste du reste** d'un tri unique : elle n'ouvre aucun
  /// chemin, et c'est sa raison d'etre, pas un defaut.
  final String? destinationStageId;

  /// Le nom du lieu atteint : « La gare » au bout de « En bus ».
  ///
  /// **Ce n'est pas [label], et c'est le point.** Le trajet dit le moyen, le
  /// lieu dit l'arrivee. Sans ce nom, l'ecran n'offrait que la lettre du lieu,
  /// et il fallait descendre chercher sa carte pour savoir ou l'on allait.
  ///
  /// Nul dans deux cas, tous deux normaux : la liste du reste d'un tri unique,
  /// qui ne mene nulle part, et une destination annoncee avant que son lieu
  /// n'existe.
  final String? destinationName;

  /// Le reperage du lieu atteint, nul tant qu'il n'existe pas.
  ///
  /// Une destination annoncee avant son lieu est une facon normale d'ecrire ;
  /// le trajet s'affiche, sans fleche d'arrivee.
  final String? destinationLetter;

  /// Vrai si le lieu atteint fait trier entre une liste et le reste.
  final bool leadsToSingleSort;

  final bool leadsToEnding;

  /// Ce que sa liste offre ici, une fois les mots communs retires.
  ///
  /// Nul tant que le trajet n'a pas de liste. C'est la question que la carte
  /// pose : en reste-t-il assez pour jouer ?
  final FamilySupply? supply;

  /// Vrai si le trajet cite au moins une liste.
  bool get hasList => supply != null;
}
