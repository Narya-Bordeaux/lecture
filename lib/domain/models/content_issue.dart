/// La nature d'une anomalie de contenu.
///
/// La distinction existe pour l'outil d'auteur. Une aventure en cours
/// d'ecriture est **toujours** invalide : le premier lieu cree n'a pas de mots,
/// aucune famille ne mene nulle part, le lieu qu'on vient d'ajouter n'est relie
/// a rien. Tout signaler de la meme facon donnerait un ecran d'alerte
/// permanent, que l'auteur apprendrait a ignorer — et le jour ou une vraie
/// faute s'y glisserait, elle passerait inapercue.
enum IssueSeverity {
  /// Ce qui reste a faire. Etat normal d'un travail en cours.
  incomplete,

  /// Ce qui ne s'arrangera pas en continuant d'ecrire, et se corrige tout de
  /// suite.
  wrong,

  /// Ce qui est permis mais merite un regard : un chemin qui ramene a un lieu
  /// deja traverse. **Ne bloque rien** — ni le jeu, ni la mention « jouable ».
  /// L'auteur garde la main : c'est lui qui sait si la boucle est voulue.
  warning,
}

/// Une anomalie relevee dans le contenu, et l'endroit ou la corriger.
///
/// Le classement vit dans le domaine et non dans l'interface : decider qu'un
/// mot ambigu est une faute alors qu'une famille vide ne l'est pas est un
/// jugement sur le contenu, pas une question d'affichage.
class ContentIssue {
  const ContentIssue({
    required this.severity,
    required this.message,
    this.stageId,
    this.familyId,
    this.wordText,
  });

  /// Ce qui reste a faire.
  const ContentIssue.incomplete(
    this.message, {
    this.stageId,
    this.familyId,
    this.wordText,
  }) : severity = IssueSeverity.incomplete;

  /// Ce qui est a corriger.
  const ContentIssue.wrong(
    this.message, {
    this.stageId,
    this.familyId,
    this.wordText,
  }) : severity = IssueSeverity.wrong;

  /// Ce qui est a verifier, sans rien empecher.
  const ContentIssue.warning(
    this.message, {
    this.stageId,
    this.familyId,
    this.wordText,
  }) : severity = IssueSeverity.warning;

  final IssueSeverity severity;

  /// Vrai si l'anomalie empeche le jeu d'ouvrir l'aventure : un manque ou une
  /// faute, jamais un simple avertissement.
  bool get blocksPlay => severity != IssueSeverity.warning;

  /// Ce qui ne va pas, en clair, a montrer tel quel.
  ///
  /// Le contenu est destine a etre ecrit a la main, et a terme par des
  /// contributeurs exterieurs : mieux vaut un diagnostic precis qu'un
  /// comportement de jeu inexplicable.
  final String message;

  /// L'etape concernee, si l'anomalie en designe une.
  ///
  /// Nulle pour ce qui vise l'aventure entiere — une etape de depart
  /// introuvable ne se rattache a aucun lieu existant.
  final String? stageId;

  /// La famille concernee, quand l'anomalie est plus fine que l'etape.
  final String? familyId;

  /// Le mot concerne, quand l'anomalie est plus fine que la famille.
  final String? wordText;

  /// Le message precede du lieu, pour une liste a plat.
  ///
  /// L'interface, elle, range deja les anomalies sous leur etape et n'a pas
  /// besoin de ce rappel.
  @override
  String toString() => stageId == null ? message : '[$stageId] $message';
}

/// Ou en est un contenu, d'un seul mot : ce que l'outil annonce en tete.
///
/// Trois etats, parce que l'auteur y fait trois choses differentes : verser
/// l'aventure dans le jeu, continuer d'ecrire, ou corriger d'abord. Un seul
/// « jouable / pas jouable » confondait le travail en cours avec la faute.
///
/// Se deduit des anomalies et de rien d'autre : une seconde regle finirait
/// par annoncer jouable une aventure que le jeu refuse.
enum ContentReadiness {
  /// Aucune anomalie : le jeu l'ouvrira.
  playable,

  /// Des manques seulement : l'etat normal d'un travail en cours.
  incomplete,

  /// Au moins une faute : a corriger avant d'aller plus loin.
  wrong;

  static ContentReadiness of(Iterable<ContentIssue> issues) {
    if (issues.any((issue) => issue.severity == IssueSeverity.wrong)) {
      return ContentReadiness.wrong;
    }
    if (issues.any((issue) => issue.severity == IssueSeverity.incomplete)) {
      return ContentReadiness.incomplete;
    }
    // Aucune anomalie, ou seulement des avertissements : le jeu l'ouvrira.
    return ContentReadiness.playable;
  }
}
