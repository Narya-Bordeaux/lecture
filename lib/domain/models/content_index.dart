/// Ce que le fichier pere annonce d'une aventure, sans la charger.
///
/// Permet a un ecran de selection de lister les aventures disponibles sans lire
/// tout leur contenu.
class AdventureEntry {
  const AdventureEntry({
    required this.id,
    required this.title,
    required this.file,
    this.coverAsset,
  });

  factory AdventureEntry.fromJson(Map<String, dynamic> json) {
    return AdventureEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      file: json['file'] as String,
      coverAsset: json['cover'] as String?,
    );
  }

  final String id;
  final String title;

  /// Chemin du fichier d'aventure, relatif au dossier du contenu.
  final String file;

  /// Illustration de presentation, absente tant qu'elle n'existe pas.
  final String? coverAsset;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'file': file,
      if (coverAsset != null) 'cover': coverAsset,
    };
  }

  @override
  String toString() => 'AdventureEntry($id)';
}

/// Le fichier pere : ce qui existe, et ou le trouver.
///
/// Il ne contient aucun contenu de jeu, seulement des chemins. C'est ce qui
/// permet d'ajouter une aventure ou un domaine de vocabulaire sans toucher au
/// code.
class ContentIndex {
  const ContentIndex({
    required this.lexiconFiles,
    required this.adventures,
    this.wordListFiles = const <String>[],
    this.charactersFile,
  });

  factory ContentIndex.fromJson(Map<String, dynamic> json) {
    return ContentIndex(
      lexiconFiles: List<String>.unmodifiable(
        (json['lexicons'] as List<dynamic>? ?? <dynamic>[]).cast<String>(),
      ),
      wordListFiles: List<String>.unmodifiable(
        (json['lists'] as List<dynamic>? ?? <dynamic>[]).cast<String>(),
      ),
      charactersFile: json['characters'] as String?,
      adventures: List<AdventureEntry>.unmodifiable(
        (json['adventures'] as List<dynamic>? ?? <dynamic>[]).map(
          (item) => AdventureEntry.fromJson(item as Map<String, dynamic>),
        ),
      ),
    );
  }

  /// Les fichiers de vocabulaire, un par domaine.
  final List<String> lexiconFiles;

  /// Les fichiers de listes de mots, un par domaine.
  ///
  /// Separes des lexiques, et pour une raison de fond : un lexique definit
  /// chaque mot une seule fois, alors qu'un mot appartient a plusieurs listes.
  final List<String> wordListFiles;

  /// Le fichier des personnages, s'il y en a.
  final String? charactersFile;

  final List<AdventureEntry> adventures;

  AdventureEntry? findAdventure(String adventureId) {
    for (final entry in adventures) {
      if (entry.id == adventureId) return entry;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'lexicons': lexiconFiles,
      if (wordListFiles.isNotEmpty) 'lists': wordListFiles,
      if (charactersFile != null) 'characters': charactersFile,
      'adventures': adventures.map((entry) => entry.toJson()).toList(),
    };
  }
}
