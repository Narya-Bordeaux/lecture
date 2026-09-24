// Ce que le francais ecrit demande au code : replier les accents.
//
// Une seule table, pour deux usages qui ne doivent pas diverger : les
// identifiants tires d'un nom (« La forêt » donne `foret`) et l'ordre
// alphabetique d'une liste de mots (« école » se range avec les « e »).

/// Les lettres accentuees, et la lettre nue qui les remplace.
const Map<String, String> _accents = <String, String>{
  'à': 'a', 'â': 'a', 'ä': 'a',
  'ç': 'c',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i',
  'ô': 'o', 'ö': 'o',
  'ù': 'u', 'û': 'u', 'ü': 'u',
  'ÿ': 'y',
  'À': 'A', 'Â': 'A', 'Ä': 'A',
  'Ç': 'C',
  'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
  'Î': 'I', 'Ï': 'I',
  'Ô': 'O', 'Ö': 'O',
  'Ù': 'U', 'Û': 'U', 'Ü': 'U',
  'Ÿ': 'Y',
};

/// Le texte sans ses accents, casse gardee : un mot francais qui reste
/// lisible (`foret`, `arret`, `Ecole`).
String foldAccents(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final character = String.fromCharCode(rune);
    buffer.write(_accents[character] ?? character);
  }
  return buffer.toString();
}
