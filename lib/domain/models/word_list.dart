import 'dart:math';

import 'package:grisbie/domain/models/lexicon.dart';
import 'package:grisbie/domain/models/word.dart';

/// Une liste de mots par theme, reutilisable d'un lieu a l'autre.
///
/// Trois objets repondent a trois questions distinctes, et c'est ce qui
/// justifie celui-ci :
///
/// | Objet | Repond a |
/// |---|---|
/// | [Word] dans le lexique | comment le mot s'ecrit et se decoupe |
/// | [WordList] | de quoi le mot parle |
/// | `WordFamily` | ou cette liste se pose ici, sous quel nom, vers quelle sortie |
///
/// Le lexique definit chaque mot **une seule fois** et refuse le doublon ; un
/// mot doit pourtant pouvoir appartenir a plusieurs themes. Une famille, elle,
/// porte un nom affiche, une destination et une zone sur l'illustration —
/// autant de choses propres a un lieu, donc non reutilisables. Il manquait
/// l'objet du milieu.
///
/// **Une liste est plus grande que la partie.** A l'entree du lieu, le moteur
/// n'en tire que quelques mots ([sample]), apres avoir retire ceux qu'elle
/// partage avec ses voisines ([without]). Rejouer la meme journee ne redonne
/// donc pas les memes mots.
class WordList {
  const WordList({
    required this.id,
    required this.name,
    required this.words,
  });

  /// Construit la liste en resolvant ses mots dans le lexique.
  ///
  /// Une liste **cite** des mots, elle n'en definit aucun : chaque mot
  /// n'existe qu'une fois, au lexique, et un mot absent du lexique est une
  /// faute de frappe qu'il vaut mieux nommer que jouer.
  factory WordList.fromJson(Map<String, dynamic> json, Lexicon lexicon) {
    final id = json['id'] as String;
    final texts =
        (json['words'] as List<dynamic>? ?? <dynamic>[]).cast<String>();

    // Un mot repete compterait deux fois dans le tirage, et pourrait paraitre
    // en double sur le bandeau. C'est le genre de doublon qu'on ne voit pas en
    // relisant une liste de vingt mots.
    final seen = <String>{};
    final duplicates = <String>[];
    for (final text in texts) {
      if (!seen.add(text)) duplicates.add(text);
    }
    if (duplicates.isNotEmpty) {
      throw FormatException(
        'Mots repetes dans la liste "$id" : ${duplicates.join(', ')}',
      );
    }

    return WordList(
      id: id,
      // Le nom sert a l'auteur pour retrouver sa liste ; l'enfant, lui, lit le
      // nom de la famille. A defaut, l'identifiant fait l'affaire.
      name: json['name'] as String? ?? id,
      words: List<Word>.unmodifiable(texts.map(lexicon.resolve)),
    );
  }

  final String id;

  /// Nom de travail, pour l'auteur. Jamais montre a l'enfant.
  final String name;

  final List<Word> words;

  int get length => words.length;

  bool get isEmpty => words.isEmpty;

  bool get isNotEmpty => words.isNotEmpty;

  Set<String> get wordTexts => words.map((word) => word.text).toSet();

  bool contains(String wordText) => words.any((word) => word.text == wordText);

  /// La meme liste, privee des mots cites.
  ///
  /// Sert a retirer ce qu'elle partage avec les autres listes du lieu : un mot
  /// present des deux cotes serait ambigu, et le jeu refuserait une bonne
  /// reponse. L'ordre d'ecriture est conserve — c'est [sample] qui melange.
  WordList without(Set<String> wordTexts) {
    if (wordTexts.isEmpty) return this;
    return copyWith(
      words: words
          .where((word) => !wordTexts.contains(word.text))
          .toList(growable: false),
    );
  }

  /// Un tirage de [count] mots, ou la liste entiere si elle est plus courte.
  ///
  /// Prendre ce qu'il y a plutot qu'echouer : un contenu trop maigre doit se
  /// jouer quand meme pendant qu'on l'ecrit. C'est `Stage.validate()` qui le
  /// signale, et l'outil d'auteur qui le montre.
  ///
  /// Le melange passe par le [Random] injecte : a graine fixee le tirage est
  /// reproductible, sans quoi aucun test du moteur ne le serait.
  WordList sample(int? count, Random random) {
    if (count == null || count >= words.length) return this;
    if (count <= 0) return copyWith(words: const <Word>[]);

    final drawn = List<Word>.of(words)..shuffle(random);
    return copyWith(words: drawn.take(count).toList(growable: false));
  }

  WordList copyWith({String? id, String? name, List<Word>? words}) {
    return WordList(
      id: id ?? this.id,
      name: name ?? this.name,
      words: words ?? this.words,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'words': words.map((word) => word.text).toList(),
    };
  }

  @override
  String toString() => 'WordList($id, ${words.length} mots)';
}
