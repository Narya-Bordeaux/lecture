import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/lexicon.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_list.dart';
import 'package:grisbie/domain/models/word_list_catalog.dart';

/// La liste de mots : l'objet reutilisable, entre le lexique et la famille.
///
/// Trois objets, trois questions distinctes. Le lexique dit **comment un mot
/// s'ecrit**, la liste dit **de quoi il parle**, la famille dit
/// **ou cette liste se pose dans ce lieu**. Un mot appartient a plusieurs
/// listes ; il n'est defini qu'une fois.

Lexicon buildLexicon(List<String> texts) {
  return Lexicon(<String, Word>{
    for (final text in texts)
      text: Word(text: text),
  });
}

void main() {
  final lexicon = buildLexicon(<String>['bus', 'arret', 'ticket', 'volant']);

  group('Une liste cite des mots, elle n\'en definit aucun', () {
    test('elle resout ses mots dans le lexique', () {
      final list = WordList.fromJson(
        <String, dynamic>{
          'id': 'bus',
          'name': 'Le bus',
          'words': <String>['arret', 'ticket'],
        },
        lexicon,
      );

      expect(list.id, 'bus');
      expect(list.name, 'Le bus');
      expect(list.wordTexts, <String>{'arret', 'ticket'});
      // Le mot vient du lexique, pas de la liste : c'est tout l'interet de la
      // separation.
      expect(list.words.first, lexicon.resolve('arret'));
    });

    test('un mot inconnu du lexique est nomme', () {
      expect(
        () => WordList.fromJson(
          <String, dynamic>{
            'id': 'bus',
            'name': 'Le bus',
            'words': <String>['trottinette'],
          },
          lexicon,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('trottinette'),
          ),
        ),
      );
    });

    test('un mot repete dans la meme liste est refuse', () {
      // Sans ce controle, le mot compterait deux fois dans le tirage et
      // pourrait s'afficher en double sur le bandeau.
      expect(
        () => WordList.fromJson(
          <String, dynamic>{
            'id': 'bus',
            'name': 'Le bus',
            'words': <String>['arret', 'ticket', 'arret'],
          },
          lexicon,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('arret'),
          ),
        ),
      );
    });

    test('ecrire puis relire rend la meme liste', () {
      final list = WordList(
        id: 'bus',
        name: 'Le bus',
        words: <Word>[lexicon.resolve('arret'), lexicon.resolve('ticket')],
      );

      final reread = WordList.fromJson(list.toJson(), lexicon);

      expect(reread.id, list.id);
      expect(reread.name, list.name);
      expect(reread.wordTexts, list.wordTexts);
    });
  });

  group('Le meme mot vit dans plusieurs listes', () {
    test('rien ne s\'y oppose, contrairement au lexique', () {
      // C'est la raison d'etre de l'objet : le lexique refuse le doublon, et
      // un mot doit pourtant pouvoir appartenir a plusieurs themes.
      final catalog = WordListCatalog.fromJson(
        <String, dynamic>{
          'lists': <dynamic>[
            <String, dynamic>{
              'id': 'bus',
              'name': 'Le bus',
              'words': <String>['arret', 'ticket'],
            },
            <String, dynamic>{
              'id': 'voiture',
              'name': 'La voiture',
              'words': <String>['volant', 'ticket'],
            },
          ],
        },
        lexicon,
      );

      expect(catalog.resolve('bus').contains('ticket'), isTrue);
      expect(catalog.resolve('voiture').contains('ticket'), isTrue);
    });

    test('deux listes de meme identifiant sont refusees', () {
      expect(
        () => WordListCatalog.fromJson(
          <String, dynamic>{
            'lists': <dynamic>[
              <String, dynamic>{'id': 'bus', 'name': 'Le bus', 'words': <String>[]},
              <String, dynamic>{'id': 'bus', 'name': 'Bis', 'words': <String>[]},
            ],
          },
          lexicon,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('bus'),
          ),
        ),
      );
    });

    test('une liste citee mais jamais ecrite est nommee', () {
      expect(
        () => WordListCatalog.empty.resolve('bus'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('bus'),
          ),
        ),
      );
    });

    test('les fichiers de listes se reunissent en un seul catalogue', () {
      final transport = WordListCatalog.fromJson(
        <String, dynamic>{
          'lists': <dynamic>[
            <String, dynamic>{'id': 'bus', 'name': 'Le bus', 'words': <String>['arret']},
          ],
        },
        lexicon,
      );
      final divers = WordListCatalog.fromJson(
        <String, dynamic>{
          'lists': <dynamic>[
            <String, dynamic>{'id': 'voiture', 'name': 'La voiture', 'words': <String>['volant']},
          ],
        },
        lexicon,
      );

      final merged = WordListCatalog.merge(<WordListCatalog>[transport, divers]);

      expect(merged.lists.keys, containsAll(<String>['bus', 'voiture']));
    });
  });
}
