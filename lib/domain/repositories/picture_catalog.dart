/// Les illustrations disponibles pour le contenu.
///
/// **Une illustration se choisit dans le depot** : l'auteur verse ses images
/// dans `assets/content/pictures/`, et l'outil les propose par leur nom. Le jeu
/// compile en meme temps embarque les memes fichiers — une image choisie ici
/// existe donc forcement dans le jeu. Rien n'est copie ni renomme.
///
/// Ce catalogue a remplace une photothegue qui copiait la photo choisie dans
/// l'appareil sous un nom fabrique (`gare_1790155902917.jpg`) : l'image vivait
/// alors sur le depot distant, jamais dans le depot git, et le jeu ne l'aurait
/// jamais vue.
///
/// Une interface parce que la liste vient du bundle, alors que tout ce qui
/// s'en sert doit s'eprouver sans lui. Volontairement sans dependance a
/// Flutter.
abstract class PictureCatalog {
  /// Les chemins des illustrations, **relatifs au dossier du contenu**
  /// (`pictures/Grisbie gare.jpg`) — tels qu'une aventure les ecrit —, tries
  /// par nom.
  Future<List<String>> listPictures();
}
