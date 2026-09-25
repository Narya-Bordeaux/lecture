/// Les chaines de l'interface, en francais.
///
/// A ne pas confondre avec le contenu pedagogique (mots, familles, recits) qui
/// vit dans « assets/content ». Ici ne figure que ce que dit l'application
/// elle-meme, jamais ce que l'enfant doit lire pour jouer.
///
/// Ton employe : on s'adresse a un enfant de 6-7 ans. Phrases courtes, verbes
/// simples, pas de vocabulaire d'interface (« valider », « selectionner »).
abstract final class UiStringsFr {
  /// Titre de l'application.
  static const String appTitle = 'Les Aventures de Grisbie';

  /// Le titre de l'accueil, en deux lignes arrondies au-dessus du logo.
  static const String homeTitleFirstLine = 'Les Aventures';
  static const String homeTitleSecondLine = 'de Grisbie';

  /// Bouton de la fin d'une aventure, qui ramene a l'accueil.
  static const String backToHome = 'Retour à l\'accueil';

  /// Etiquette d'accessibilite d'une vignette de l'accueil.
  static String adventureSemantics(String title) => 'L\'aventure $title';

  /// Bouton de la page de garde, qui ouvre l'aventure.
  static const String startAdventure = 'C\'est parti !';

  /// Bouton de depart vers une destination ouverte.
  static String departTo(String familyLabel) => 'Partir $familyLabel';

  /// Annonce faite quand une premiere destination s'ouvre.
  static const String destinationOpened = 'Un chemin est ouvert !';

  /// Etat de remplissage d'une famille, par exemple « 1 / 2 ».
  static String familyProgress(int placed, int total) => '$placed / $total';

  /// Message des etapes terminales, ou l'aventure s'arrete.
  static const String adventureEnd = 'Fin de l\'aventure';

  /// Bouton de reprise depuis une etape terminale.
  static const String startOver = 'Recommencer';

  /// Affiche pendant le chargement du contenu.
  static const String loading = 'Un instant...';

  /// Affiche si le contenu ne peut pas etre charge.
  static const String loadingFailed = 'Le jeu n\'a pas pu s\'ouvrir.';

  /// Etiquette d'accessibilite d'un mot a deplacer.
  static String wordSemantics(String word) => 'Le mot $word, a deplacer';

  /// Etiquette d'accessibilite d'une zone de depot.
  static String familySemantics(String label, int placed, int total) =>
      'Zone $label, $placed mot sur $total';
}
