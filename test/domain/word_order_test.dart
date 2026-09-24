import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/text/french_text.dart';

/// L'ordre alphabetique d'une liste de mots, tel qu'un lecteur francais
/// l'attend : les accents et les majuscules ne deplacent pas un mot.
void main() {
  test('les accents ne comptent pas : « école » se range avec les « e »', () {
    final words = <Word>[
      const Word(text: 'zèbre'),
      const Word(text: 'école'),
      const Word(text: 'Arbre'),
      const Word(text: 'éléphant'),
      const Word(text: 'eau'),
    ]..sort(Word.compareAlphabetically);

    expect(
      words.map((word) => word.text),
      <String>['Arbre', 'eau', 'école', 'éléphant', 'zèbre'],
    );
  });

  test('l\'ordre est stable entre deux mots de meme lettres', () {
    // « pêche » et « pèche » se replient pareil : l'ordre ne doit pas
    // dependre de l'ordre d'arrivee.
    final one = <Word>[const Word(text: 'pêche'), const Word(text: 'pèche')]
      ..sort(Word.compareAlphabetically);
    final other = <Word>[const Word(text: 'pèche'), const Word(text: 'pêche')]
      ..sort(Word.compareAlphabetically);

    expect(one.map((w) => w.text), other.map((w) => w.text));
  });

  test('le repliement des accents garde un mot francais lisible', () {
    expect(foldAccents('Forêt Ça'), 'Foret Ca');
  });
}
