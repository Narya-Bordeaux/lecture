import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/character.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';

/// La nature du lieu qu'un trajet atteint.
enum TripKind {
  /// Un lieu ordinaire : l'enfant y classera des mots dans des familles.
  ordinary,

  /// Une rencontre : un personnage y pose une question, et l'enfant trie
  /// entre le theme et un classeur de rebut.
  encounter,
}

/// Ce que l'auteur demande en ajoutant un trajet : un nom, et une nature.
class NewTrip {
  const NewTrip({required this.name, this.kind = TripKind.ordinary});

  /// Ce que l'enfant lira sur la zone de depot, et le nom du lieu atteint.
  final String name;

  final TripKind kind;
}

/// Construit un parcours en ajoutant des trajets, un point apres l'autre.
///
/// L'aventure est immutable : chaque ajout en rend une nouvelle.
///
/// **L'identifiant nait du nom, puis s'en detache.** « La gare » donne `gare`
/// a la creation, et renommer le lieu ensuite ne le touche plus. Un
/// identifiant qui suivrait le nom casserait, a chaque renommage, toutes les
/// destinations qui le citent — et le nom du fichier d'illustration avec.
class AdventureBuilder {
  const AdventureBuilder(this.adventure);

  /// Une aventure neuve, reduite a son point de depart.
  ///
  /// Elle est **incomplete et non fausse** : le lieu de depart n'a ni trajet ni
  /// marqueur de fin, ce qui est exactement l'etat d'un travail qui commence.
  /// C'est a l'auteur de la prolonger, trajet par trajet.
  static Adventure createAdventure({
    required String title,
    required String startName,
  }) {
    final startId = slugify(startName);

    return Adventure(
      id: slugify(title),
      title: title,
      startStageId: startId,
      stages: Map<String, Stage>.unmodifiable(<String, Stage>{
        startId: Stage(id: startId, locationName: startName),
      }),
    );
  }

  final Adventure adventure;

  /// Les articles qu'on retire en tete d'un nom pour en tirer l'identifiant.
  ///
  /// « La gare » donne `gare`, « Le garage » donne `garage` : exactement les
  /// identifiants que l'auteur ecrivait deja a la main dans le contenu livre.
  static const List<String> _leadingArticles = <String>[
    'le', 'la', 'les', 'l', 'un', 'une', 'des', 'du', 'au', 'aux',
  ];

  /// Les accents, retires un a un.
  ///
  /// L'identifiant finira dans un nom de fichier — l'illustration d'un lieu
  /// s'appelle d'apres lui. Un accent ou une apostrophe y est un vrai ennui.
  /// Le resultat reste un mot francais lisible : `arret`, `marche`, `foret`.
  static const Map<String, String> _accents = <String, String>{
    'à': 'a', 'â': 'a', 'ä': 'a',
    'ç': 'c',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i',
    'ô': 'o', 'ö': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u',
    'ÿ': 'y',
  };

  /// L'identifiant tire d'un nom affiche.
  ///
  /// Ne garantit pas l'unicite : c'est [addTrips] qui suffixe un homonyme.
  static String slugify(String name) {
    var text = name.toLowerCase();
    for (final entry in _accents.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    final words = text
        .split(RegExp(r"[^a-z0-9]+"))
        .where((word) => word.isNotEmpty)
        .toList();

    // L'article de tete tombe, sauf s'il ne reste rien : « Le » seul doit
    // quand meme produire un identifiant.
    if (words.length > 1 && _leadingArticles.contains(words.first)) {
      words.removeAt(0);
    }

    if (words.isEmpty) return 'lieu';
    return words.join('_');
  }

  /// Ajoute des trajets partant d'un lieu, et cree les lieux qu'ils atteignent.
  ///
  /// Les lieux neufs naissent **incomplets** et jamais faux : sans famille pour
  /// un lieu ordinaire, avec son seul classeur de rebut pour une rencontre.
  /// C'est l'etat normal d'un travail en cours, et l'outil le montre comme tel.
  Adventure addTrips(String fromStageId, List<NewTrip> trips) {
    final source = adventure.findStage(fromStageId);
    if (source == null) {
      throw StateError('Lieu inconnu : "$fromStageId".');
    }

    final stages = Map<String, Stage>.from(adventure.stages);
    final families = List<WordFamily>.from(source.families);

    for (final trip in trips) {
      final stageId = _freeId(slugify(trip.name), stages.keys.toSet());
      stages[stageId] = _arrivalOf(trip, stageId);

      families.add(WordFamily(
        id: _freeFamilyId(slugify(trip.name), families),
        label: trip.name,
        words: const <Word>[],
        destinationStageId: stageId,
      ));
    }

    // Un lieu auquel on ajoute des trajets cesse d'etre une fin : sinon le
    // marqueur et la structure se contrediraient, et `validate()` le refuserait
    // — a juste titre, puisque les mots classes ouvriraient un chemin depuis
    // une fin.
    stages[fromStageId] = source.copyWith(
      families: List<WordFamily>.unmodifiable(families),
      isEnding: false,
    );

    return Adventure(
      id: adventure.id,
      title: adventure.title,
      startStageId: adventure.startStageId,
      opening: adventure.opening,
      stages: Map<String, Stage>.unmodifiable(stages),
    );
  }

  /// Le lieu qu'un trajet atteint, a sa naissance.
  Stage _arrivalOf(NewTrip trip, String stageId) {
    if (trip.kind == TripKind.ordinary) {
      return Stage(id: stageId, locationName: trip.name);
    }

    // Une rencontre n'est pas seulement un lieu avec un portrait : la
    // specification veut que le personnage pose une question, et que l'enfant
    // trie entre le theme et un classeur de rebut. Le poser d'office evite un
    // lieu ne a moitie.
    return Stage(
      id: stageId,
      locationName: trip.name,
      encounter: Encounter(
        character: Character(id: stageId, name: trip.name),
        line: '',
      ),
      families: List<WordFamily>.unmodifiable(<WordFamily>[
        const WordFamily(
          id: 'a_laisser',
          // Nom provisoire : comment nommer ce second classeur reste une
          // question ouverte (voir docs/TODO.md). « Laisse-le » est un tri par
          // rejet, et deux gestes positifs seraient peut-etre plus justes a
          // six ans.
          label: 'Laisse-le',
          words: <Word>[],
        ),
      ]),
    );
  }

  /// Un identifiant de lieu libre, suffixe s'il est deja pris.
  static String _freeId(String wanted, Set<String> taken) {
    if (!taken.contains(wanted)) return wanted;

    var suffix = 2;
    while (taken.contains('${wanted}_$suffix')) {
      suffix++;
    }
    return '${wanted}_$suffix';
  }

  /// Un identifiant de famille libre dans ce lieu.
  ///
  /// Les familles ne se nomment que dans leur etape : deux etapes peuvent
  /// chacune avoir la leur nommee `en_bus` sans se gener.
  static String _freeFamilyId(String wanted, List<WordFamily> existing) {
    return _freeId(wanted, existing.map((family) => family.id).toSet());
  }
}
