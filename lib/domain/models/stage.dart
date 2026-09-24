import 'dart:math';

import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/narrative.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/models/word_list.dart';
import 'package:grisbie/domain/models/word_list_catalog.dart';

/// Ce que l'enfant fait dans un lieu.
///
/// **Lu dans la structure, jamais declare** — sauf la fin, qui l'est pour une
/// raison expliquee sur [Stage.isEnding]. Arrive a la gare, l'enfant range
/// dans plusieurs listes, fait un tri unique, ou lit la fin de sa journee.
/// Un lieu qu'on vient de creer n'est encore rien de tout cela : c'est a
/// l'auteur de le dire, et l'outil le lui demande sur la carte du lieu.
enum StageNature {
  /// Ni famille, ni fin : un lieu pose, pas encore ecrit.
  undefined,

  /// Plusieurs listes, chacune ouvrant un chemin.
  sorting,

  /// Une liste et tout le reste, une seule sortie.
  singleSort,

  /// Du texte, pas de jeu : la journee s'arrete la.
  ending,
}

/// Une etape du parcours : un lieu, des familles a remplir, et les chemins
/// qu'elles ouvrent.
///
/// La nature de l'etape se lit dans sa structure, sans avoir a la declarer :
/// une famille sans destination fait un tri unique, une etape sans famille est
/// une arrivee. Declarer le type en plus serait une information en double, qui
/// finirait par contredire le contenu.
class Stage {
  const Stage({
    required this.id,
    required this.locationName,
    // Un lieu qu'on vient de poser n'a pas encore de famille : c'est un etat
    // legitime depuis que la fin se declare, et `validate()` le signale comme
    // incomplet.
    this.families = const <WordFamily>[],
    this.narrative = Narrative.none,
    this.backgroundAsset,
    this.backgroundColor,
    this.visibleWordCount = 6,
    this.isEnding = false,
    this.drawCount,
  });

  /// Lit une couleur ecrite « #RRGGBB » dans le contenu.
  static int? parseColor(Object? value) {
    if (value is! String) return null;
    final hex = value.startsWith('#') ? value.substring(1) : value;
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null || hex.length != 6) return null;
    return 0xFF000000 | parsed;
  }

  /// Construit l'etape en resolvant ses listes de mots.
  factory Stage.fromJson(
    Map<String, dynamic> json, {
    required WordListCatalog lists,
  }) {
    return Stage(
      id: json['id'] as String,
      locationName: json['location'] as String,
      narrative: Narrative.fromJson(json['narrative']),
      backgroundAsset: json['background'] as String?,
      backgroundColor: parseColor(json['backgroundColor']),
      visibleWordCount: json['visibleWordCount'] as int? ?? 6,
      isEnding: json['ending'] as bool? ?? false,
      drawCount: json['drawCount'] as int?,
      families: List<WordFamily>.unmodifiable(
        (json['families'] as List<dynamic>? ?? <dynamic>[])
            .map((item) => WordFamily.fromJson(
                  item as Map<String, dynamic>,
                  lists,
                )),
      ),
    );
  }

  final String id;

  /// Le lieu ou se deroule l'etape, par exemple « La gare ».
  final String locationName;

  /// Ce que raconte l'etape, a l'arrivee et au depart.
  final Narrative narrative;

  /// L'illustration de fond, sur laquelle les zones sont posees.
  final String? backgroundAsset;

  /// La couleur qui comble la bande laissee libre au-dessus de l'illustration.
  ///
  /// L'illustration est montree en entier et calee en bas ; sur un telephone
  /// allonge, il reste de la place au-dessus. Une couleur prise dans le ciel de
  /// l'image rend la jointure invisible.
  final int? backgroundColor;

  final List<WordFamily> families;

  /// Combien de mots sont proposes en meme temps.
  ///
  /// Les autres attendent en reserve : un mot bien classe libere son
  /// emplacement, qu'un mot de la reserve vient reprendre.
  ///
  /// A ne pas confondre avec [drawCount] : celui-ci dit combien de mots
  /// **chaque famille** met en jeu, celui-la combien d'etiquettes tiennent a
  /// l'ecran, toutes familles confondues.
  final int visibleWordCount;

  /// Combien de mots chaque famille tire de sa liste, sauf mention contraire.
  ///
  /// Nul, les listes jouent entieres — ce qu'il en reste une fois les mots
  /// communs retires. C'est le comportement d'un contenu qui ne demande rien,
  /// et celui du contenu livre.
  ///
  /// Une famille peut demander autre chose (`WordFamily.drawCount`) : les
  /// listes n'ont pas a etre de la meme taille d'un theme a l'autre.
  final int? drawCount;

  /// Tous les mots de l'etape, qui sont ceux de ses familles.
  ///
  /// La liste est derivee et non declaree : la declarer en plus obligerait a
  /// verifier qu'elle concorde avec les familles, et elle finirait par en
  /// diverger.
  List<Word> get words {
    return List<Word>.unmodifiable(
      families.expand((family) => family.words),
    );
  }

  /// Vrai si l'etape clot le parcours.
  ///
  /// Declare, et non deduit de l'absence de famille. Une etape qu'on vient de
  /// creer et qu'on n'a pas encore ecrite n'en a pas non plus : sans ce
  /// marqueur, un lieu oublie passerait pour une fin, et `validate()` n'aurait
  /// rien a dire.
  ///
  /// C'est bien une information en double avec la structure, ce que le projet
  /// evite d'ordinaire. La contrepartie est que la redondance est
  /// **verifiable** : `validate()` refuse qu'une fin porte des familles, et
  /// signale un lieu sans famille qui ne se declare pas fin. Les deux ne
  /// peuvent donc pas diverger en silence.
  final bool isEnding;

  /// Vrai si l'etape fait trier entre **une liste et son complement**.
  ///
  /// Autre mecanique de lecture que le tri entre plusieurs familles : au lieu
  /// de comparer les mots entre eux, avec un choix qui se reduit a mesure,
  /// l'enfant juge chaque mot seul contre un seul critere — il est du theme,
  /// ou il n'en est pas. C'est plus abstrait, et plus difficile.
  ///
  /// La structure le dit, rien n'est declare : une famille sans destination
  /// **est** la liste du reste. Corollaire verifie par `validate()`, un tri
  /// unique n'a qu'une sortie ; deux en feraient un tri ordinaire affuble
  /// d'une liste de rebut.
  bool get isSingleSort =>
      families.any((family) => !family.leadsSomewhere);

  /// Ce que l'enfant fait ici. Voir [StageNature].
  StageNature get nature {
    if (isEnding) return StageNature.ending;
    if (families.isEmpty) return StageNature.undefined;
    if (isSingleSort) return StageNature.singleSort;
    return StageNature.sorting;
  }

  Word? findWord(String wordText) {
    for (final family in families) {
      for (final word in family.words) {
        if (word.text == wordText) return word;
      }
    }
    return null;
  }

  WordFamily? findFamily(String familyId) {
    for (final family in families) {
      if (family.id == familyId) return family;
    }
    return null;
  }

  /// Combien de mots chaque zone tire, sans reglage : sept (decision de
  /// l'auteur, 0.42.0).
  ///
  /// La zone « le reste » aussi : elle tire sept mots dans l'ensemble de ses
  /// listes cochees, et non sept par liste. Une liste de moins de sept mots
  /// est **a finir** — [validate] le signale, et la zone n'est pas jouee
  /// entiere en silence.
  static const int defaultDrawCount = 7;

  /// Combien de mots cette famille met en jeu ici.
  ///
  /// La famille l'emporte sur le reglage du lieu, qui l'emporte sur
  /// [defaultDrawCount]. Sans reglage, la liste jouait entiere : une zone de
  /// douze mots s'annoncait « 0 / 12 » et en exigeait douze.
  int drawCountFor(WordFamily family) =>
      family.drawCount ?? drawCount ?? defaultDrawCount;

  /// Les mots que cette famille partage avec les autres listes du lieu.
  ///
  /// Un mot present des deux cotes serait ambigu : l'enfant le classerait
  /// justement, et le jeu refuserait sa reponse. Plutot que d'interdire le
  /// partage a l'auteur — ce qui se verifiait a la main, liste contre liste —
  /// on retire le mot des deux cotes avant qu'il n'arrive a l'ecran.
  ///
  /// Ecrire le meme mot dans deux listes devient ainsi la facon de declarer
  /// qu'il est ambigu **ici** : ailleurs, sans la liste voisine, il jouera.
  ///
  /// **Un tri unique est asymetrique.** Le reste se definit par le theme — il
  /// puise dans des listes choisies, moins les mots du theme — et le theme,
  /// lui, garde tous les siens : en retirer « pomme » parce qu'une liste
  /// d'objets la contient aussi n'aurait aucun sens.
  Set<String> sharedWordTextsIn(WordFamily family) {
    final themeOfSingleSort = isSingleSort && family.leadsSomewhere;

    final others = <String>{};
    for (final other in families) {
      if (identical(other, family) || other.id == family.id) continue;
      if (themeOfSingleSort && !other.leadsSomewhere) continue;
      others.addAll(other.list.wordTexts);
    }
    return family.list.wordTexts.intersection(others);
  }

  /// Ce que cette famille offre ici : ses mots, ceux qu'elle perd, ce qui
  /// reste, et ce qu'on lui demande.
  ///
  /// C'est la question que la carte du lieu pose pour chaque liste : une fois
  /// retires les mots communs, en reste-t-il assez pour jouer ?
  FamilySupply supplyOf(WordFamily family) {
    final shared = sharedWordTextsIn(family);
    return FamilySupply(
      total: family.list.length,
      shared: shared.length,
      required: drawCountFor(family),
    );
  }

  /// Vrai si le lieu peut se jouer seul, pour que l'auteur l'essaie.
  ///
  /// Il faut des familles, et que chacune garde au moins un mot une fois les
  /// mots communs retires. Une famille vide s'ouvrirait d'elle-meme, sans que
  /// rien ait ete trie : l'essai mentirait sur ce que l'enfant vivra. Une fin,
  /// ou un lieu a definir, n'a rien a trier.
  bool get canBeTriedAlone =>
      families.isNotEmpty &&
      families.every((family) => supplyOf(family).available > 0);

  /// Ce qu'il reste a cette famille une fois les mots communs retires.
  ///
  /// C'est dans cette liste-la que le tirage puise, et c'est elle que
  /// [validate] mesure : « assez de mots » n'est pas une propriete de la liste
  /// mais de **la liste a ce lieu-la**, puisque les voisines changent d'un
  /// lieu a l'autre.
  WordList availableWordsIn(WordFamily family) {
    return family.list.without(sharedWordTextsIn(family));
  }

  /// L'etape telle qu'elle se joue : chaque famille reduite a son tirage.
  ///
  /// Le lieu garde son identite — memes familles, memes noms, memes zones —
  /// seules les listes retrecissent. Une liste etant plus grande que la
  /// partie, deux entrees dans le meme lieu ne donnent pas les memes mots :
  /// c'est ce qui permet de rejouer une journee sans la reciter.
  Stage drawnWith(Random random) {
    if (families.isEmpty) return this;

    return copyWith(
      families: List<WordFamily>.unmodifiable(<WordFamily>[
        for (final family in families)
          family.copyWith(
            list: availableWordsIn(family).sample(drawCountFor(family), random),
          ),
      ]),
    );
  }

  /// Les incoherences de contenu, classees et situees.
  ///
  /// Le contenu pedagogique est destine a etre ecrit a la main, et a terme par
  /// des contributeurs exterieurs : mieux vaut un diagnostic precis qu'un
  /// comportement de jeu inexplicable.
  ///
  /// Chaque anomalie dit si elle est **fausse** — a corriger tout de suite, car
  /// continuer d'ecrire ne l'arrangera pas — ou seulement **incomplete**, ce
  /// qui est l'etat normal d'un lieu qu'on vient de creer. Voir
  /// [IssueSeverity].
  List<ContentIssue> validate() {
    final issues = <ContentIssue>[];

    for (final family in families) {
      if (family.lists.isEmpty) {
        // Un trajet qu'on vient de poser, ou le reste d'un tri unique dont
        // l'auteur n'a pas encore coche les listes.
        issues.add(ContentIssue.incomplete(
          family.leadsSomewhere
              ? 'La famille "${family.id}" n\'a pas encore de liste de mots.'
              : 'La famille "${family.id}" ne puise encore dans aucune liste.',
          stageId: id,
          familyId: family.id,
        ));
      } else if (family.words.isEmpty) {
        // Une famille qu'on vient de creer n'a pas encore ses mots.
        issues.add(ContentIssue.incomplete(
          'La famille "${family.id}" ne contient aucun mot.',
          stageId: id,
          familyId: family.id,
        ));
      }

      issues.addAll(_validateSupplyOf(family));

    }

    // Une etape dont aucune famille ne mene ailleurs est un cul-de-sac. Fatal
    // dans une aventure finie, mais tout lieu neuf l'est jusqu'a ce qu'on le
    // relie : c'est du travail restant, pas une faute.
    if (families.isNotEmpty && !families.any((family) => family.leadsSomewhere)) {
      issues.add(ContentIssue.incomplete(
        'Aucune famille ne mene ailleurs : l\'etape serait sans issue.',
        stageId: id,
      ));
    }

    // Le tri unique tient a ce qu'il n'y ait qu'un seul choix : une liste, et
    // tout le reste. Deux sorties en feraient autre chose.
    if (isSingleSort && families.where((f) => f.leadsSomewhere).length > 1) {
      issues.add(ContentIssue.wrong(
        'Ce lieu fait trier entre une liste et le reste, mais propose '
        'plusieurs sorties : un tri unique n\'en a qu\'une.',
        stageId: id,
      ));
    }

    // Le marqueur de fin fait double emploi avec la structure. C'est assume,
    // a condition qu'on ne puisse pas les faire mentir l'un sur l'autre.
    if (isEnding && families.isNotEmpty) {
      issues.add(ContentIssue.wrong(
        'L\'etape se declare fin mais porte des familles : les mots classes '
        'ouvriraient un chemin depuis une fin.',
        stageId: id,
      ));
    }
    if (!isEnding && families.isEmpty) {
      issues.add(ContentIssue.incomplete(
        'L\'etape n\'a aucune famille et ne se declare pas fin : lieu pose, '
        'mais pas encore ecrit.',
        stageId: id,
      ));
    }

    issues.addAll(_validateAreas());

    return issues;
  }

  /// Verifie qu'il reste de quoi jouer une fois l'exclusion faite.
  ///
  /// Le mot partage n'est plus une faute — c'est meme la facon de le declarer
  /// ambigu ici. Ce qui devient une anomalie, c'est le **manque** qu'il
  /// laisse : deux listes qui se recouvrent trop ne remplissent plus le lieu.
  ///
  /// Deux cas, et ils ne se corrigent pas de la meme facon :
  ///
  /// - il en manque quelques-uns — **incomplet**, le remede est d'en ecrire
  ///   d'autres, ce qui est le geste normal de l'ecriture ;
  /// - l'exclusion vide entierement la liste — **faux**, les deux listes
  ///   disent alors la meme chose, et continuer d'ecrire n'y changera rien.
  List<ContentIssue> _validateSupplyOf(WordFamily family) {
    if (family.list.isEmpty) return const <ContentIssue>[];

    final supply = supplyOf(family);

    if (supply.available == 0) {
      return <ContentIssue>[
        ContentIssue.wrong(
          'Tous les mots de la famille "${family.id}" se retrouvent dans les '
          'autres listes de ce lieu : apres exclusion il n\'en reste aucun a '
          'jouer.',
          stageId: id,
          familyId: family.id,
        ),
      ];
    }

    // Rien n'a ete promis : l'auteur joue avec ce qui reste.
    if (supply.isEnough) return const <ContentIssue>[];

    return <ContentIssue>[
      ContentIssue.incomplete(
        'La famille "${family.id}" demande ${supply.required} mots ; apres '
        'exclusion des ${supply.shared} mots communs aux autres listes du '
        'lieu, il n\'en reste que ${supply.available}.',
        stageId: id,
        familyId: family.id,
      ),
    ];
  }

  /// Verifie les zones de depot posees sur l'illustration.
  ///
  /// Une zone mal posee est toujours une faute : elle ne se repare pas en
  /// continuant d'ecrire, et le doigt de l'enfant en paierait le prix. Une
  /// zone absente, elle, n'est qu'un manque.
  List<ContentIssue> _validateAreas() {
    final issues = <ContentIssue>[];
    final placed = <WordFamily>[];

    for (final family in families) {
      final area = family.area;
      if (area == null) {
        // Dans le jeu, une famille sans zone n'est pas affichee : ses mots ne
        // se poseraient nulle part, et le lieu ne se terminerait pas. Un
        // manque et non une faute — on cale les zones une fois l'image posee.
        //
        // **Seulement sur un lieu illustre** : les zones se calent sur l'image,
        // et sans elle il n'y a encore rien a caler. C'est aussi ce qui garde
        // ouvrable le contenu livre, dont deux lieux attendent leur decor.
        if (backgroundAsset != null) {
          issues.add(ContentIssue.incomplete(
            'La famille "${family.id}" n\'a pas de zone de depot sur '
            'l\'illustration : ses mots ne pourraient se poser nulle part.',
            stageId: id,
            familyId: family.id,
          ));
        }
        continue;
      }

      if (area.overflows) {
        issues.add(ContentIssue.wrong(
          'La zone de la famille "${family.id}" deborde de l\'illustration.',
          stageId: id,
          familyId: family.id,
        ));
      }
      for (final other in placed) {
        if (area.overlaps(other.area!)) {
          issues.add(ContentIssue.wrong(
            'Les zones des familles "${other.id}" et "${family.id}" se '
            'chevauchent : le depot serait ambigu.',
            stageId: id,
            familyId: family.id,
          ));
        }
      }
      placed.add(family);
    }

    return issues;
  }

  Stage copyWith({
    String? id,
    String? locationName,
    Narrative? narrative,
    List<WordFamily>? families,
    String? backgroundAsset,
    int? backgroundColor,
    int? visibleWordCount,
    bool? isEnding,
    int? drawCount,
    bool clearBackgroundAsset = false,
  }) {
    return Stage(
      id: id ?? this.id,
      locationName: locationName ?? this.locationName,
      narrative: narrative ?? this.narrative,
      families: families ?? this.families,
      // `??` garde l'ancienne valeur : sans ce geste explicite, retirer une
      // illustration serait sans effet, et l'auteur croirait l'avoir fait.
      backgroundAsset: clearBackgroundAsset
          ? null
          : backgroundAsset ?? this.backgroundAsset,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      visibleWordCount: visibleWordCount ?? this.visibleWordCount,
      isEnding: isEnding ?? this.isEnding,
      drawCount: drawCount ?? this.drawCount,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'location': locationName,
      if (!narrative.isEmpty) 'narrative': narrative.toJson(),
      if (backgroundAsset != null) 'background': backgroundAsset,
      if (backgroundColor != null)
        'backgroundColor':
            '#${(backgroundColor! & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
      // Ecrit seulement quand il vaut quelque chose : une etape ordinaire n'a
      // pas a porter « ending: false ».
      if (isEnding) 'ending': true,
      'visibleWordCount': visibleWordCount,
      if (drawCount != null) 'drawCount': drawCount,
      'families': families.map((family) => family.toJson()).toList(),
    };
  }

  @override
  String toString() => 'Stage($id)';
}

/// Ce qu'une famille offre dans un lieu, une fois les mots communs retires.
///
/// Une valeur et non un message : la carte du lieu l'affiche a sa facon, et
/// `validate()` en tire ses anomalies. Deux calculs separes finiraient par
/// ne plus dire la meme chose.
class FamilySupply {
  const FamilySupply({
    required this.total,
    required this.shared,
    required this.required,
  });

  /// Les mots de la liste — ou des listes reunies.
  final int total;

  /// Ceux qui partent, parce qu'ils sont aussi dans une liste voisine.
  final int shared;

  /// Combien de mots la partie demande a cette famille. Nul, la liste joue
  /// entiere.
  final int? required;

  /// Ce qui reste a jouer.
  int get available => total - shared;

  /// Vrai s'il reste de quoi jouer : au moins [required] mots, ou au moins un
  /// quand rien n'est demande.
  bool get isEnough => available >= (required ?? 1);
}
