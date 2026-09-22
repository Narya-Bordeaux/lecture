/// Le compte de l'auteur sur le depot distant.
///
/// Une interface parce que l'interface graphique ne doit rien savoir du
/// fournisseur : elle montre un etat et transmet deux gestes. Les tests en
/// passent une fausse, et l'outil s'en passe entierement quand aucun depot
/// n'est configure.
///
/// Volontairement sans dependance a Flutter ni a Firebase.
abstract class AuthorAccount {
  /// L'identifiant de l'auteur connecte, nul s'il ne l'est pas.
  ///
  /// C'est **cet** identifiant que la regle du bucket doit nommer : l'outil
  /// l'affiche pour qu'on puisse le recopier sans aller le chercher.
  String? get userId;

  bool get isSignedIn;

  /// Se connecte. Rend `null` si c'est fait, un message clair sinon.
  Future<String?> signIn({required String email, required String password});

  Future<void> signOut();
}
