import 'package:grisbie/domain/models/character.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/lexicon.dart';
import 'package:grisbie/domain/models/narrative.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';

/// Une etape du parcours : un lieu, des familles a remplir, et les chemins
/// qu'elles ouvrent.
///
/// La nature de l'etape se lit dans sa structure, sans avoir a la declarer :
/// une etape avec un [encounter] est une rencontre, une etape sans famille est
/// une arrivee. Declarer le type en plus serait une information en double, qui
/// finirait par contredire le contenu.
class Stage {
  const Stage({
    required this.id,
    required this.locationName,
    required this.families,
    this.narrative = Narrative.none,
    this.backgroundAsset,
    this.backgroundColor,
    this.encounter,
    this.visibleWordCount = 6,
  });

  /// Lit une couleur ecrite « #RRGGBB » dans le contenu.
  static int? parseColor(Object? value) {
    if (value is! String) return null;
    final hex = value.startsWith('#') ? value.substring(1) : value;
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null || hex.length != 6) return null;
    return 0xFF000000 | parsed;
  }

  /// Construit l'etape en resolvant mots et personnages.
  factory Stage.fromJson(
    Map<String, dynamic> json, {
    required Lexicon lexicon,
    required Map<String, Character> characters,
  }) {
    final encounter = json['character'] as Map<String, dynamic>?;

    return Stage(
      id: json['id'] as String,
      locationName: json['location'] as String,
      narrative: Narrative.fromJson(json['narrative']),
      backgroundAsset: json['background'] as String?,
      backgroundColor: parseColor(json['backgroundColor']),
      visibleWordCount: json['visibleWordCount'] as int? ?? 6,
      encounter: encounter == null
          ? null
          : Encounter(
              character: _resolveCharacter(
                encounter['id'] as String,
                characters,
              ),
              line: encounter['line'] as String,
            ),
      families: List<WordFamily>.unmodifiable(
        (json['families'] as List<dynamic>? ?? <dynamic>[])
            .map((item) => WordFamily.fromJson(
                  item as Map<String, dynamic>,
                  lexicon,
                )),
      ),
    );
  }

  static Character _resolveCharacter(
    String id,
    Map<String, Character> characters,
  ) {
    final character = characters[id];
    if (character == null) {
      throw FormatException('Personnage inconnu : "$id"');
    }
    return character;
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

  /// Le personnage rencontre ici, s'il y en a un.
  final Encounter? encounter;

  final List<WordFamily> families;

  /// Combien de mots sont proposes en meme temps.
  ///
  /// Les autres attendent en reserve : un mot bien classe libere son
  /// emplacement, qu'un mot de la reserve vient reprendre.
  final int visibleWordCount;

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

  /// Une etape sans famille clot le parcours.
  bool get isTerminal => families.isEmpty;

  /// Vrai si l'etape met en scene un personnage.
  bool get isEncounter => encounter != null;

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
    final owners = <String, String>{};

    for (final family in families) {
      if (family.words.isEmpty) {
        // Une famille qu'on vient de creer n'a pas encore ses mots.
        issues.add(ContentIssue.incomplete(
          'La famille "${family.id}" ne contient aucun mot.',
          stageId: id,
          familyId: family.id,
        ));
      }

      for (final word in family.words) {
        // Un mot classable dans deux familles de la meme etape est exactement
        // le « mot ambigu » que la specification proscrit : le jeu refuserait
        // une bonne reponse.
        final owner = owners[word.text];
        if (owner != null) {
          issues.add(ContentIssue.wrong(
            'Le mot "${word.text}" est ambigu : il appartient aux familles '
            '"$owner" et "${family.id}".',
            stageId: id,
            familyId: family.id,
            wordText: word.text,
          ));
        }
        owners[word.text] = family.id;

        if (word.syllables.isEmpty) {
          // Le mot est pose, ses syllabes restent a taper.
          issues.add(ContentIssue.incomplete(
            'Le mot "${word.text}" n\'a pas de decoupage.',
            stageId: id,
            familyId: family.id,
            wordText: word.text,
          ));
        }

        // Un mot dont le texte se retrouve dans le nom de sa famille se classe
        // en comparant les lettres, sans comprendre le sens.
        if (family.label.toLowerCase().contains(word.text.toLowerCase())) {
          issues.add(ContentIssue.wrong(
            'Le mot "${word.text}" apparait dans le nom de sa famille '
            '"${family.label}" : il se classerait sans etre compris.',
            stageId: id,
            familyId: family.id,
            wordText: word.text,
          ));
        }
      }
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

    issues.addAll(_validateAreas());

    return issues;
  }

  /// Verifie les zones de depot posees sur l'illustration.
  ///
  /// Ces anomalies sont toujours des fautes : une zone mal posee ne se repare
  /// pas en continuant d'ecrire, et le doigt de l'enfant en paierait le prix.
  List<ContentIssue> _validateAreas() {
    final issues = <ContentIssue>[];
    final placed = <WordFamily>[];

    for (final family in families) {
      final area = family.area;
      if (area == null) continue;

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
    Encounter? encounter,
    int? visibleWordCount,
  }) {
    return Stage(
      id: id ?? this.id,
      locationName: locationName ?? this.locationName,
      narrative: narrative ?? this.narrative,
      families: families ?? this.families,
      backgroundAsset: backgroundAsset ?? this.backgroundAsset,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      encounter: encounter ?? this.encounter,
      visibleWordCount: visibleWordCount ?? this.visibleWordCount,
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
      if (encounter != null) 'character': encounter!.toJson(),
      'visibleWordCount': visibleWordCount,
      'families': families.map((family) => family.toJson()).toList(),
    };
  }

  @override
  String toString() => 'Stage($id)';
}
