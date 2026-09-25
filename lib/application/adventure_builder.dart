import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/text/french_text.dart';
import 'package:grisbie/domain/models/stage.dart';
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
  /// Le defaut du domaine ([Stage.defaultDrawCount]), et une seule constante :
  /// l'outil le pose encore sur le lieu (`Stage.drawCount`) des qu'il recoit
  /// ses listes, ce qui rend le reglage visible dans le fichier.
  static const int defaultDrawCount = Stage.defaultDrawCount;

  /// Les articles qu'on retire en tete d'un nom pour en tirer l'identifiant.
  ///
  /// « La gare » donne `gare`, « Le garage » donne `garage` : exactement les
  /// identifiants que l'auteur ecrivait deja a la main dans le contenu livre.
  static const List<String> _leadingArticles = <String>[
    'le', 'la', 'les', 'l', 'un', 'une', 'des', 'du', 'au', 'aux',
  ];

  /// L'identifiant tire d'un nom affiche.
  ///
  /// Ne garantit pas l'unicite : c'est [addTrips] qui suffixe un homonyme.
  static String slugify(String name) {
    // L'identifiant finira dans un nom de fichier — l'illustration d'un lieu
    // s'appelle d'apres lui. Un accent ou une apostrophe y est un vrai ennui ;
    // le resultat reste un mot francais lisible : `arret`, `marche`, `foret`.
    final text = foldAccents(name.toLowerCase());

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
        // Une famille neuve pour chaque lieu : deux tris uniques ne
        // partagent jamais leur reste.
        _restFamily(<WordFamily>[theme]),
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

  /// Renomme un trajet : ce que l'enfant lit sur la zone de depot.
  ///
  /// L'identifiant ne suit pas, comme pour un lieu : il est cite par les
  /// zones calees et, dans le jeu, par les departs.
  Adventure renameTrip(String stageId, String familyId, String label) {
    final wanted = label.trim();
    if (wanted.isEmpty) {
      throw ArgumentError.value(label, 'label', 'Un trajet porte un nom');
    }
    return _changeFamily(
      stageId,
      familyId,
      (family) => family.copyWith(label: wanted),
    );
  }

  /// Fait mener un trajet a un autre lieu **deja ecrit**, quel qu'il soit.
  ///
  /// Une boucle devient possible — revenir a un lieu deja traverse — et c'est
  /// voulu : `validate()` la signale comme *a verifier*, sans l'interdire.
  /// Le lieu qu'on quitte reste, detache si plus rien n'y mene.
  Adventure redirectTrip(String stageId, String familyId, String destinationId) {
    _require(destinationId);
    return _changeFamily(stageId, familyId, (family) {
      if (!family.leadsSomewhere) {
        throw StateError(
          'Le reste d\'un tri unique ne mene nulle part : c\'est ce qui en '
          'fait le reste.',
        );
      }
      return family.copyWith(destinationStageId: destinationId);
    });
  }

  /// Retire un trajet. Le lieu qu'il desservait reste, detache s'il n'est
  /// plus atteint : **rien ne disparait sans que l'auteur l'ait decide**.
  ///
  /// La nature du lieu suit sa structure : retirer le dernier trajet le rend
  /// a definir, retirer le reste d'un tri unique en fait un lieu a listes.
  Adventure removeTrip(String stageId, String familyId) {
    final source = _require(stageId);
    if (source.findFamily(familyId) == null) {
      throw StateError('Trajet inconnu : "$stageId" / "$familyId".');
    }
    return _withStages(Map<String, Stage>.from(adventure.stages)
      ..[stageId] = source.copyWith(
        families: List<WordFamily>.unmodifiable(
          source.families.where((family) => family.id != familyId),
        ),
      ));
  }

  /// Fait d'un lieu a plusieurs listes un **tri unique**.
  ///
  /// Le trajet choisi devient le theme et garde sa liste ; les autres
  /// partent — leurs lieux restent, detaches. Le reste nait sans liste :
  /// l'auteur cochera celles ou puiser.
  Adventure convertToSingleSort(String stageId, {required String themeFamilyId}) {
    final source = _require(stageId);
    final theme = source.findFamily(themeFamilyId);
    if (theme == null || !theme.leadsSomewhere) {
      throw StateError(
        'Le thème doit être un trajet de "$stageId" : "$themeFamilyId".',
      );
    }

    return _withStages(Map<String, Stage>.from(adventure.stages)
      ..[stageId] = source.copyWith(
        families: List<WordFamily>.unmodifiable(<WordFamily>[
          theme,
          _restFamily(<WordFamily>[theme]),
        ]),
        drawCount: source.drawCount ?? defaultDrawCount,
      ));
  }

  /// Fait d'un tri unique un lieu a plusieurs listes : le reste part, le
  /// theme reste un trajet ordinaire, et on pourra en ajouter d'autres.
  Adventure convertToSorting(String stageId) {
    final source = _require(stageId);
    return _withStages(Map<String, Stage>.from(adventure.stages)
      ..[stageId] = source.copyWith(
        families: List<WordFamily>.unmodifiable(
          source.families.where((family) => family.leadsSomewhere),
        ),
      ));
  }

  /// Fait d'un lieu une fin : ses trajets partent, leurs lieux restent.
  Adventure convertToEnding(String stageId) {
    final source = _require(stageId);
    return _withStages(Map<String, Stage>.from(adventure.stages)
      ..[stageId] = source.copyWith(
        families: const <WordFamily>[],
        isEnding: true,
      ));
  }

  /// Rouvre une fin : le lieu redevient a definir, et sa carte repose la
  /// question. C'est le remede a une fin creee par erreur.
  Adventure reopen(String stageId) {
    final source = _require(stageId);
    if (!source.isEnding) {
      throw StateError('Le lieu "$stageId" n\'est pas une fin.');
    }
    return _withStages(Map<String, Stage>.from(adventure.stages)
      ..[stageId] = source.copyWith(isEnding: false));
  }

  /// Supprime un lieu que plus aucun trajet n'atteint.
  ///
  /// Un lieu encore atteint laisserait un trajet mener nulle part ; le point
  /// de depart, une aventure sans entree. Les deux sont refuses.
  Adventure removeStage(String stageId) {
    _require(stageId);
    if (stageId == adventure.startStageId) {
      throw StateError('Le point de départ ne se supprime pas.');
    }
    for (final stage in adventure.stages.values) {
      for (final family in stage.families) {
        if (family.destinationStageId == stageId && stage.id != stageId) {
          throw StateError(
            'Le trajet "${family.label}" mène encore à ce lieu : '
            'retirez-le ou redirigez-le d\'abord.',
          );
        }
      }
    }
    return _withStages(Map<String, Stage>.from(adventure.stages)..remove(stageId));
  }

  /// La liste du reste d'un tri unique, nee sans liste.
  static WordFamily _restFamily(List<WordFamily> existing) {
    return WordFamily(
      id: _freeFamilyId('le_reste', existing),
      // Nom provisoire : comment nommer cette seconde liste reste une
      // question ouverte (voir docs/TODO.md).
      label: 'Le reste',
      lists: const <WordList>[],
    );
  }

  Adventure _changeFamily(
    String stageId,
    String familyId,
    WordFamily Function(WordFamily family) change,
  ) {
    final source = _require(stageId);
    if (source.findFamily(familyId) == null) {
      throw StateError('Trajet inconnu : "$stageId" / "$familyId".');
    }
    return _withStages(Map<String, Stage>.from(adventure.stages)
      ..[stageId] = source.copyWith(
        families: List<WordFamily>.unmodifiable(<WordFamily>[
          for (final family in source.families)
            family.id == familyId ? change(family) : family,
        ]),
      ));
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
        // **Aucune liste encore.** L'auteur en creera une ou en reutilisera
        // une existante, depuis l'ecran de liste : il n'y a pas de mot seul.
        // Une liste vide posee d'office aurait pris un identifiant tire du
        // trajet — `en_bus` —, que deux aventures auraient pu se disputer
        // dans le catalogue, l'une ecrasant l'autre a l'enregistrement.
        lists: const <WordList>[],
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
      coverAsset: adventure.coverAsset,
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
    final stageId = freeId(slugify(trip.arrivalName), stages.keys.toSet());
    // Il nait a definir : ce que l'enfant y fera se dit sur sa carte.
    stages[stageId] = Stage(id: stageId, locationName: trip.arrivalName);
    return stageId;
  }

  /// Un identifiant libre, suffixe s'il est deja pris : `gare`, `gare_2`…
  static String freeId(String wanted, Set<String> taken) {
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
    return freeId(wanted, existing.map((family) => family.id).toSet());
  }
}
