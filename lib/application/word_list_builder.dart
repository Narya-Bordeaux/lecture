import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/models/word_library.dart';
import 'package:grisbie/domain/models/word_list.dart';

/// Un endroit ou une liste sert : un trajet, dans un lieu.
class ListUsage {
  const ListUsage({
    required this.stageId,
    required this.familyId,
    required this.locationName,
    required this.familyLabel,
  });

  final String stageId;
  final String familyId;

  /// « La gare » : ce que l'auteur reconnait.
  final String locationName;

  /// « En bus » : le trajet qui cite la liste.
  final String familyLabel;
}

/// Compose les listes de mots d'une aventure.
///
/// **Il n'y a pas de mot seul.** Un mot entre toujours par une liste, et une
/// liste se cree ou se reutilise pour un trajet. C'est le pendant de
/// [AdventureBuilder], un etage plus bas : l'aventure est immutable, et chaque
/// geste en rend une nouvelle.
///
/// **L'aventure fait foi, la bibliotheque vient derriere.** Une liste deja
/// modifiee dans l'aventure l'emporte sur sa version enregistree ; un mot
/// ecrit plus tot dans la seance est connu comme s'il venait du lexique. Sans
/// cela, reutiliser une liste qu'on vient de retoucher ramenerait sa version
/// d'avant.
///
/// **Une liste est la meme partout ou elle sert.** La modifier depuis un
/// trajet la modifie pour tous ceux qui la citent — c'est ce qui la rend
/// reutilisable. [usagesOf] permet de le dire avant de toucher.
class WordListBuilder {
  const WordListBuilder(this.adventure, {this.library = WordLibrary.empty});

  final Adventure adventure;

  /// Le vocabulaire deja ecrit, ailleurs que dans cette aventure.
  final WordLibrary library;

  /// Les syllabes d'un decoupage tape au clavier : `a-rê`, `a · rê`, `a rê`.
  ///
  /// Tiret, point median, barre ou espace : on separe comme on en a
  /// l'habitude, sans avoir a apprendre une convention.
  static List<String> parseSyllables(String typed) {
    return typed
        .split(RegExp(r'[-·/\s]+'))
        .where((syllable) => syllable.isNotEmpty)
        .toList(growable: false);
  }

  /// Un decoupage tel qu'on le retape : `a-rê`.
  static String formatSyllables(List<String> syllables) => syllables.join('-');

  /// Les listes de l'aventure, par identifiant — celles qui font foi.
  Map<String, WordList> get _adventureLists => <String, WordList>{
        for (final list in adventure.wordLists) list.id: list,
      };

  /// Toutes les listes qu'on peut citer, triees par nom.
  List<WordList> get knownLists {
    final byId = <String, WordList>{
      ...library.lists.lists,
      ..._adventureLists,
    };
    return byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  WordList? findList(String listId) {
    return _adventureLists[listId] ?? library.lists.lists[listId];
  }

  /// Le mot tel qu'il est deja defini : dans l'aventure, sinon au lexique.
  Word? findWord(String text) {
    final wanted = text.trim();
    for (final list in adventure.wordLists) {
      for (final word in list.words) {
        if (word.text == wanted) return word;
      }
    }
    return library.lexicon.words[wanted];
  }

  /// Les trajets de l'aventure qui citent cette liste, dans l'ordre des lieux.
  List<ListUsage> usagesOf(String listId) {
    return <ListUsage>[
      for (final stage in adventure.stages.values)
        for (final family in stage.families)
          if (family.lists.any((list) => list.id == listId))
            ListUsage(
              stageId: stage.id,
              familyId: family.id,
              locationName: stage.locationName,
              familyLabel: family.label,
            ),
    ];
  }

  /// Donne au trajet une liste neuve, vide, nommee [name].
  ///
  /// L'identifiant nait du nom, et ne reprend aucune liste connue : le
  /// catalogue est global, et un doublon ferait refuser tout le contenu.
  Adventure createListFor(
    String stageId,
    String familyId, {
    required String name,
  }) {
    final taken = knownLists.map((list) => list.id).toSet();
    final id = AdventureBuilder.freeId(AdventureBuilder.slugify(name), taken);
    return _replaceFamily(
      stageId,
      familyId,
      (family) => family.copyWith(
        list: WordList(id: id, name: name.trim(), words: const <Word>[]),
      ),
    );
  }

  /// Fait citer au trajet une liste qui existe deja.
  Adventure useListFor(String stageId, String familyId, String listId) {
    final list = _requireKnown(listId);
    return _replaceFamily(
      stageId,
      familyId,
      (family) => family.copyWith(list: list),
    );
  }

  /// Coche les listes ou le **reste** d'un tri unique prend ses mots.
  ///
  /// Le jeu y tirera des mots absents du theme. Seul le reste puise dans
  /// plusieurs listes : un trajet qui ouvre un chemin n'en cite qu'une.
  Adventure setPooledLists(
    String stageId,
    String familyId,
    List<String> listIds,
  ) {
    final lists = listIds.map(_requireKnown).toList(growable: false);
    return _replaceFamily(stageId, familyId, (family) {
      if (family.leadsSomewhere) {
        throw StateError(
          'Le trajet "${family.id}" ouvre un chemin : il cite une seule liste. '
          'Seul le reste d\'un tri unique puise dans plusieurs.',
        );
      }
      return family.copyWith(lists: lists);
    });
  }

  /// Ajoute un mot a une liste citee par l'aventure.
  ///
  /// Un mot deja connu garde son decoupage : le lexique n'en admet qu'un, et
  /// [syllables] est alors ignore — [changeSyllables] sert a le corriger. Un
  /// mot neuf, lui, ne s'ajoute pas sans son decoupage : il n'est jamais
  /// calcule.
  Adventure addWord(
    String listId, {
    required String text,
    List<String>? syllables,
  }) {
    final list = _requireCited(listId);
    final wanted = text.trim();
    if (wanted.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Un mot ne peut pas etre vide');
    }
    if (list.contains(wanted)) {
      throw StateError('"$wanted" est deja dans la liste "${list.name}".');
    }

    final known = findWord(wanted);
    final cleaned = _cleanSyllables(syllables);
    if (known == null && cleaned.isEmpty) {
      throw ArgumentError.value(
        syllables,
        'syllables',
        '"$wanted" est un mot neuf : son decoupage est a saisir',
      );
    }

    final added = known ?? Word(text: wanted, syllables: cleaned);
    return _replaceList(
      list.copyWith(words: List<Word>.unmodifiable(<Word>[...list.words, added])),
    );
  }

  /// Retire un mot d'une liste. Il reste au lexique, ou d'autres listes
  /// peuvent le citer.
  Adventure removeWord(String listId, String text) {
    final list = _requireCited(listId);
    return _replaceList(list.without(<String>{text}));
  }

  /// Corrige le decoupage d'un mot, partout ou l'aventure le cite.
  Adventure changeSyllables(String text, List<String> syllables) {
    final cleaned = _cleanSyllables(syllables);
    if (cleaned.isEmpty) {
      throw ArgumentError.value(syllables, 'syllables', 'Decoupage vide');
    }

    var result = adventure;
    for (final list in adventure.wordLists) {
      if (!list.contains(text)) continue;
      result = WordListBuilder(result, library: library)._replaceList(
        list.copyWith(
          words: List<Word>.unmodifiable(<Word>[
            for (final word in list.words)
              word.text == text ? Word(text: text, syllables: cleaned) : word,
          ]),
        ),
      );
    }
    return result;
  }

  /// Renomme une liste. Son identifiant ne suit pas : il est cite ailleurs.
  Adventure renameList(String listId, String name) {
    final list = _requireCited(listId);
    return _replaceList(list.copyWith(name: name.trim()));
  }

  WordList _requireKnown(String listId) {
    final list = findList(listId);
    if (list == null) throw StateError('Liste inconnue : "$listId".');
    return list;
  }

  /// Une liste que l'aventure cite. Modifier une liste que rien ne cite
  /// n'aurait aucun effet visible, et rien ne l'enregistrerait.
  WordList _requireCited(String listId) {
    final list = _adventureLists[listId];
    if (list == null) {
      throw StateError(
        'La liste "$listId" n\'est citee par aucun trajet de cette aventure.',
      );
    }
    return list;
  }

  static List<String> _cleanSyllables(List<String>? syllables) {
    return <String>[
      for (final syllable in syllables ?? const <String>[])
        if (syllable.trim().isNotEmpty) syllable.trim(),
    ];
  }

  /// Remplace une liste partout ou l'aventure la cite.
  Adventure _replaceList(WordList replacement) {
    var result = adventure;
    for (final stage in adventure.stages.values) {
      if (!stage.families.any(
        (family) => family.lists.any((list) => list.id == replacement.id),
      )) {
        continue;
      }
      result = result.withStage(stage.copyWith(
        families: List<WordFamily>.unmodifiable(<WordFamily>[
          for (final family in stage.families)
            family.copyWith(
              lists: <WordList>[
                for (final list in family.lists)
                  list.id == replacement.id ? replacement : list,
              ],
            ),
        ]),
      ));
    }
    return result;
  }

  Adventure _replaceFamily(
    String stageId,
    String familyId,
    WordFamily Function(WordFamily family) change,
  ) {
    final Stage? stage = adventure.findStage(stageId);
    final family = stage?.findFamily(familyId);
    if (stage == null || family == null) {
      throw StateError('Trajet inconnu : "$stageId" / "$familyId".');
    }

    return adventure.withStage(stage.copyWith(
      families: List<WordFamily>.unmodifiable(<WordFamily>[
        for (final each in stage.families)
          each.id == familyId ? change(each) : each,
      ]),
    ));
  }
}
