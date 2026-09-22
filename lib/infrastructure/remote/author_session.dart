import 'package:firebase_auth/firebase_auth.dart';
import 'package:grisbie/domain/repositories/author_account.dart';

/// La connexion de l'auteur au depot distant.
///
/// **Par e-mail et mot de passe, pas par Google.** Google sur Android suppose
/// d'enregistrer les empreintes SHA-1 des magasins de cles, ce qui marche en
/// debug et casse en release ; l'e-mail se comporte a l'identique sur le web et
/// sur un telephone, sans greffon de plus. L'usage est solo : un seul compte,
/// cree a la main dans la console, et la regle du bucket nomme son UID.
class AuthorSession implements AuthorAccount {
  const AuthorSession({required this.auth});

  final FirebaseAuth auth;

  /// L'identifiant de l'auteur connecte, nul s'il ne l'est pas.
  ///
  /// C'est **cet** identifiant que la regle du bucket doit nommer. L'outil
  /// l'affiche pour qu'on puisse le recopier sans aller le chercher.
  @override
  String? get userId => auth.currentUser?.uid;

  @override
  bool get isSignedIn => userId != null;

  /// Se connecte, et rend un message d'echec plutot qu'une exception brute.
  ///
  /// Les codes de Firebase — `invalid-credential`, `network-request-failed` —
  /// ne disent rien a qui les lit sur un telephone.
  @override
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (error) {
      return describeFailure(error.code);
    } catch (error) {
      return 'Connexion impossible : $error';
    }
  }

  @override
  Future<void> signOut() => auth.signOut();

  /// Ce qu'un code d'erreur de Firebase veut dire, en clair.
  ///
  /// Pur, et donc eprouvable sans reseau ni compte.
  static String describeFailure(String code) {
    return switch (code) {
      'invalid-email' => 'Cette adresse n\'est pas une adresse valide.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' =>
        'Adresse ou mot de passe incorrect.',
      'user-disabled' => 'Ce compte est désactivé dans la console.',
      'network-request-failed' =>
        'Pas de réseau : le dépôt distant est injoignable.',
      'too-many-requests' =>
        'Trop de tentatives. Réessayer dans quelques minutes.',
      _ => 'Connexion refusée ($code).',
    };
  }
}
