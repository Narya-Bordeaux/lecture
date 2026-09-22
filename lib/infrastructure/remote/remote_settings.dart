/// Ce qu'il faut savoir pour joindre le depot distant de l'auteur.
///
/// **Rien de tout cela n'entre dans le depot.** Les valeurs arrivent par
/// `--dart-define` au lancement (voir `docs/Commandes.md`) : pas de fichier a
/// ignorer par git, pas de cle recopiee dans le code, et le dossier se compile
/// sans elles.
///
/// Absentes, [isComplete] est faux et l'outil s'en passe — il enregistre en
/// local. C'est le meme parti que la photothegue : une capacite manquante ne
/// casse rien, elle ne se propose simplement pas.
class RemoteSettings {
  const RemoteSettings({
    required this.apiKey,
    required this.appId,
    required this.projectId,
    required this.messagingSenderId,
    required this.storageBucket,
    this.authDomain,
  });

  /// Les valeurs telles que le lancement les donne.
  ///
  /// Separe de la lecture des `--dart-define`, qui est constante a la
  /// compilation et donc ineprouvable : ici tout se passe en valeurs ordinaires.
  factory RemoteSettings.fromValues(Map<String, String> values) {
    String read(String key) => values[key]?.trim() ?? '';

    return RemoteSettings(
      apiKey: read('apiKey'),
      appId: read('appId'),
      projectId: read('projectId'),
      messagingSenderId: read('messagingSenderId'),
      storageBucket: read('storageBucket'),
      authDomain: read('authDomain').isEmpty ? null : read('authDomain'),
    );
  }

  final String apiKey;
  final String appId;
  final String projectId;
  final String messagingSenderId;
  final String storageBucket;

  /// Le domaine de connexion, que seul le web reclame.
  final String? authDomain;

  /// Les champs sans lesquels aucune connexion n'est possible.
  ///
  /// `authDomain` n'en est pas : il ne sert qu'au web, et le laisser
  /// obligatoire empecherait de lancer l'outil sur un telephone.
  static const List<String> requiredKeys = <String>[
    'apiKey',
    'appId',
    'projectId',
    'messagingSenderId',
    'storageBucket',
  ];

  /// Vrai quand tout ce qu'il faut est la.
  bool get isComplete => missingKeys.isEmpty;

  /// Ce qui manque, nomme.
  ///
  /// Un message qui dit « configuration incomplete » sans dire laquelle se
  /// cherche a l'aveugle, et ces valeurs se recopient une a une d'une console.
  List<String> get missingKeys {
    final values = <String, String>{
      'apiKey': apiKey,
      'appId': appId,
      'projectId': projectId,
      'messagingSenderId': messagingSenderId,
      'storageBucket': storageBucket,
    };
    return <String>[
      for (final entry in values.entries)
        if (entry.value.isEmpty) entry.key,
    ];
  }
}
