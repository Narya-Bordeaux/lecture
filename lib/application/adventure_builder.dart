import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/models/word_list.dart';

/// Ce que l'auteur demande en ajoutant un trajet : deux noms.
///
/// **Un trajet n'a pas de nature.** Ce que l'enfant fera au bout se decide
/// sur la carte du lieu atteint, une fois qu'il existe — la question est
/// « que fait l'enfant ici ? », et elle se pose au lieu, pas au chemin.
class NewTrip {
  const NewTrip({
    required this.name,
    this.locationName,
    this.existingStageId,
  });

  /// Ce que l'enfant lira sur la zone de depot : « En bus ».
  final String name;

  /// Le nom du lieu atteint : « La gare ».
  ///
  /// **Ce n'est pas le meme que [name], et c'est le point.** L'enfant classe
  /// des mots sous « En bus », puis decouvre « La gare » : le trajet dit le
  /// moyen, le lieu dit l'arrivee. L'outil les confondait, ce qui le rendait
  /// incapable d'ecrire le contenu livre.
  ///
  /// Nul ou vide, le trajet prete le sien — le cas courant, ou l'un vaut
  /// l'autre. Sans effet quand [existingStageId] est donne : le lieu existe,
  /// et le renommer depuis un chemin qui le rejoint changerait son titre a
  /// l'insu des autres.
  final String? locationName;

  /// Le nom que portera le lieu cree.
  String get arrivalName {
    final wanted = locationName?.trim() ?? '';
    return wanted.isEmpty ? name : wanted;
  }

  /// Le lieu deja ecrit que ce trajet rejoint, au lieu d'en creer un.
  ///
  /// Sert d'abord aux **fins** : une fin porte un ecran, une illustration et un
  /// texte, et deux chemins qui aboutissent au meme endroit doivent partager la
  /// meme. Sans cela l'auteur ecrirait deux fois la meme arrivee, et les deux
  /// finiraient par differer.
  final String? existingStageId;
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

  /// Combien de mots chaque liste met en jeu, dans un lieu que l'outil ecrit.
  ///
  /// Pose sur le lieu (`Stage.drawCount`) des qu'il recoit ses listes. Une
  /// liste peut en compter bien davantage : c'est ce qui fait qu'une journee
  /// rejouee ne redonne pas les memes mots. C'est aussi le seuil que la carte
  /// du lieu compare a ce qui reste une fois les mots communs retires.
  static const int defaultDrawCount = 7;

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
  /// Chaque trajet porte sa liste : le lieu devient — ou reste — un lieu a
  /// **plusieurs listes**. Les lieux atteints naissent **a definir** : ce que
  /// l'enfant y fera se decide ensuite, sur leur propre carte.
  Adventure addTrips(String fromStageId, List<NewTrip> trips) {
    final source = _require(fromStageId);

    // Un tri unique n'a qu'une sortie : c'est ce qui le distingue d'un tri
    // ordinaire affuble d'une liste de rebut. L'interface n'en propose donc
    // jamais plus d'une, et le moteur le garantit.
    final exits = source.families.where((f) => f.leadsSomewhere).length;
    if (source.isSingleSort && exits + trips.length > 1) {
      throw StateError(
        'Le lieu "$fromStageId" fait trier entre une liste et le reste : '
        'il n\'accepte qu\'une seule sortie.',
      );
    }

    final stages = Map<String, Stage>.from(adventure.stages);
    final families = List<WordFamily>.from(source.families)
      ..addAll(_familiesFor(trips, source.families, stages));

    // Un lieu auquel on ajoute des trajets cesse d'etre une fin : sinon le
    // marqueur et la structure se contrediraient, et `validate()` le refuserait
    // — a juste titre, puisque les mots classes ouvriraient un chemin depuis
    // une fin.
    //
    // Le nombre de mots n'est pose que sur un lieu qui recoit ses premieres
    // listes : un lieu deja ecrit garde ce qu'il demandait, contenu livre
    // compris.
    stages[fromStageId] = source.copyWith(
      families: List<WordFamily>.unmodifiable(families),
      isEnding: false,
      drawCount: source.families.isEmpty
          ? source.drawCount ?? defaultDrawCount
          : null,
    );

    return _withStages(stages);
  }

  /// Fait d'un lieu a definir un **tri unique** : une liste et tout le reste.
  ///
  /// Les deux familles naissent ensemble, parce que l'une sans l'autre n'est
  /// pas un tri unique : le theme, qui ouvre [exit], et le reste, qui n'ouvre
  /// rien. C'est la seule sortie du lieu.
  Adventure defineAsSingleSort(String stageId, NewTrip exit) {
    final source = _requireUndefined(stageId);
    final stages = Map<String, Stage>.from(adventure.stages);

    final theme = _familiesFor(<NewTrip>[exit], source.families, stages).single;
    stages[stageId] = source.copyWith(
      families: List<WordFamily>.unmodifiable(<WordFamily>[
        theme,
        // **Pas `const`** : Dart canoniserait l'objet, et deux tris uniques
        // partageraient litteralement la meme famille. Elles sont
        // immutables, donc rien ne pourrait diverger — mais il ne faut pas
        // avoir a le demontrer pour etre tranquille. Chaque lieu a la sienne.
        WordFamily(
          id: _freeFamilyId('le_reste', <WordFamily>[theme]),
          // Nom provisoire : comment nommer cette seconde liste reste une
          // question ouverte (voir docs/TODO.md). Un tri par rejet n'est
          // peut-etre pas le geste le plus juste a six ans.
          label: 'Le reste',
          list: _newList('${stageId}_le_reste', 'Le reste de $stageId'),
        ),
      ]),
      drawCount: source.drawCount ?? defaultDrawCount,
    );

    return _withStages(stages);
  }

  /// Declare qu'un lieu a definir clot la journee : du texte, pas de jeu.
  Adventure defineAsEnding(String stageId) {
    final source = _requireUndefined(stageId);
    final stages = Map<String, Stage>.from(adventure.stages)
      ..[stageId] = source.copyWith(isEnding: true);
    return _withStages(stages);
  }

  /// Les familles de ces trajets, et les lieux qu'ils atteignent.
  ///
  /// [stages] est enrichi des lieux crees au passage.
  List<WordFamily> _familiesFor(
    List<NewTrip> trips,
    List<WordFamily> existing,
    Map<String, Stage> stages,
  ) {
    final taken = List<WordFamily>.of(existing);
    final created = <WordFamily>[];

    for (final trip in trips) {
      final stageId = _arrivalIdOf(trip, stages);
      final familyId = _freeFamilyId(slugify(trip.name), taken);
      final family = WordFamily(
        id: familyId,
        label: trip.name,
        // Une liste neuve, vide, nommee d'apres le trajet. L'auteur la
        // remplira, et pourra la rattacher ailleurs : c'est le propre d'une
        // liste que de servir a plusieurs lieux.
        list: _newList(familyId, trip.name),
        destinationStageId: stageId,
      );
      taken.add(family);
      created.add(family);
    }

    return created;
  }

  Stage _require(String stageId) {
    final stage = adventure.findStage(stageId);
    if (stage == null) {
      throw StateError('Lieu inconnu : "$stageId".');
    }
    return stage;
  }

  /// Un lieu dont la nature n'est pas encore dite.
  ///
  /// Redefinir un lieu deja ecrit jetterait ses listes ou ses trajets : ce
  /// n'est pas un geste que l'outil fait sans le dire.
  Stage _requireUndefined(String stageId) {
    final stage = _require(stageId);
    if (stage.nature != StageNature.undefined) {
      throw StateError(
        'Le lieu "$stageId" est deja defini : on ne change pas ce que '
        'l\'enfant y fait sans en retirer d\'abord les trajets.',
      );
    }
    return stage;
  }

  Adventure _withStages(Map<String, Stage> stages) {
    return Adventure(
      id: adventure.id,
      title: adventure.title,
      startStageId: adventure.startStageId,
      opening: adventure.opening,
      stages: Map<String, Stage>.unmodifiable(stages),
    );
  }

  /// L'identifiant du lieu qu'atteint ce trajet, cree au besoin.
  ///
  /// Rejoindre un lieu deja ecrit n'en cree aucun : c'est ce qui permet a
  /// plusieurs chemins d'aboutir a la meme fin, avec un seul ecran a ecrire.
  /// [stages] est enrichi au passage, si bien que deux trajets crees d'un coup
  /// ne peuvent pas se donner le meme identifiant.
  String _arrivalIdOf(NewTrip trip, Map<String, Stage> stages) {
    final existing = trip.existingStageId;
    if (existing != null) {
      if (!stages.containsKey(existing)) {
        throw StateError('Lieu inconnu : "$existing".');
      }
      return existing;
    }

    // L'identifiant vient du **lieu**, pas du trajet : « La gare » donne
    // `gare`, exactement ce que le contenu livre ecrit a la main.
    final stageId = _freeId(slugify(trip.arrivalName), stages.keys.toSet());
    // Il nait a definir : ce que l'enfant y fera se dit sur sa carte.
    stages[stageId] = Stage(id: stageId, locationName: trip.arrivalName);
    return stageId;
  }

  /// Une liste vide, prete a recevoir des mots.
  ///
  /// **Pas `const`** : Dart canonise les constantes, et deux listes vides de
  /// meme identifiant seraient litteralement le meme objet. Elles sont
  /// immutables, donc rien ne pourrait diverger — mais il ne faut pas avoir a
  /// le demontrer pour etre tranquille.
  static WordList _newList(String id, String name) {
    return WordList(id: id, name: name, words: <Word>[]);
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
