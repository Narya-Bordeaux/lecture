import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_index.dart';
import 'package:grisbie/domain/repositories/author_account.dart';
import 'package:grisbie/domain/repositories/picture_catalog.dart';
import 'package:grisbie/domain/models/word_library.dart';
import 'package:grisbie/infrastructure/content/content_repository.dart';
import 'package:grisbie/ui/pages/author_sign_in_page.dart';
import 'package:grisbie/ui/pages/new_adventure_page.dart';
import 'package:grisbie/ui/pages/outline_page.dart';

/// Le sommaire de l'outil d'auteur : les aventures, et de quoi en créer une.
///
/// **Il lit ce que l'outil a écrit**, avec le contenu livré pour repli
/// (`FallbackContentSource`) : sans cela, on enregistrerait une aventure sans
/// jamais pouvoir la rouvrir.
///
/// Et il l'ouvre par `loadDraft`, jamais par `loadAdventure` : une aventure en
/// cours d'écriture est **toujours** invalide — un lieu qu'on vient de créer
/// n'a pas ses mots — et `loadAdventure` la refuserait. C'est le contrat « le
/// jeu refuse, l'outil tolère ».
class AuthorHomePage extends StatefulWidget {
  const AuthorHomePage({
    required this.openRepository,
    this.pictures,
    this.onSave,
    this.account,
    super.key,
  });

  /// Ouvre le contenu, **à neuf**.
  ///
  /// Une fabrique et non une instance, pour deux raisons. `ContentRepository`
  /// garde le sommaire et les lexiques en mémoire — c'est ce qu'il faut pour
  /// jouer — si bien qu'un dépôt déjà lu ne verrait pas ce qu'on vient d'y
  /// enregistrer. Et se connecter **change la source** : le sommaire du dépôt
  /// distant n'est pas celui de l'appareil.
  ///
  /// Le type est concret à dessein : `loadDraft` n'appartient pas à
  /// l'interface que le jeu emploie.
  final ContentRepository Function() openRepository;

  /// Les images du dépôt, transmises aux éditeurs.
  ///
  /// Pas une fabrique, contrairement au dépôt de contenu : les images viennent
  /// du bundle, que se connecter ne change pas.
  final PictureCatalog? pictures;

  /// Ce qui écrit une aventure. Nul, l'écran du parcours ne le propose pas.
  final Future<List<String>> Function(Adventure adventure)? onSave;

  /// Le compte de l'auteur sur le dépôt distant.
  ///
  /// Nul quand le lancement n'a pas configuré de dépôt : l'outil enregistre
  /// alors sur l'appareil, et n'en parle pas.
  final AuthorAccount? account;

  @override
  State<AuthorHomePage> createState() => _AuthorHomePageState();
}

class _AuthorHomePageState extends State<AuthorHomePage> {
  late ContentRepository _repository;
  late Future<ContentIndex> _index;

  @override
  void initState() {
    super.initState();
    _reopen();
  }

  /// Rouvre le contenu et relit son sommaire.
  ///
  /// Après un enregistrement, pour voir apparaître ce qu'on vient d'écrire ;
  /// après une connexion, parce qu'on ne lit plus au même endroit.
  void _reopen() {
    _repository = widget.openRepository();
    _index = _repository.loadIndex();
  }

  void _reload() => setState(_reopen);

  /// Ouvre une aventure existante, **même inachevée**.
  Future<void> _openAdventure(AdventureEntry entry) async {
    final Adventure adventure;
    try {
      adventure = await _repository.loadDraft(entry.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contenu illisible : $error')),
      );
      return;
    }
    if (!mounted) return;

    await _openOutline(adventure);
  }

  /// Crée une aventure neuve et enchaîne aussitôt sur son parcours.
  Future<void> _startNewAdventure() async {
    final fresh = await askForNewAdventure(context);
    if (fresh == null || !mounted) return;

    await _openOutline(fresh);
  }

  Future<void> _openOutline(Adventure adventure) async {
    // Le vocabulaire deja ecrit : pour reutiliser une liste, et retrouver le
    // decoupage d'un mot au lieu de le redemander. Illisible, on ouvre quand
    // meme le parcours — on pourra toujours creer des listes.
    WordLibrary library = WordLibrary.empty;
    try {
      library = await _repository.loadLibrary();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vocabulaire illisible : $error')),
        );
      }
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<Adventure>(
        builder: (_) => OutlinePage(
          adventure: adventure,
          pictures: widget.pictures,
          contentSource: _repository.source,
          onSave: widget.onSave,
          library: library,
        ),
      ),
    );
    // Une aventure enregistrée depuis le parcours doit apparaître ici.
    if (mounted) _reload();
  }

  Future<void> _signIn(AuthorAccount account) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AuthorSignInPage(account: account),
      ),
    );
    if (!mounted) return;

    // Se connecter change d'où l'on lit et où l'on écrit : le sommaire du
    // dépôt distant n'est pas celui de l'appareil.
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outil d\'auteur')),
      body: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Nouvelle aventure'),
            subtitle: const Text('Partir d\'une page blanche'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _startNewAdventure,
          ),
          const Divider(height: 1),
          _buildAccountTile(context),
          Expanded(child: _buildAdventures(context)),
        ],
      ),
    );
  }

  Widget _buildAdventures(BuildContext context) {
    return FutureBuilder<ContentIndex>(
      future: _index,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Sommaire illisible :\n\n${snapshot.error}'),
          );
        }
        final index = snapshot.data;
        if (index == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.separated(
          itemCount: index.adventures.length,
          separatorBuilder: (context, position) => const Divider(height: 1),
          itemBuilder: (context, position) {
            final entry = index.adventures[position];
            return ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(entry.title),
              subtitle: Text(entry.id),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openAdventure(entry),
            );
          },
        );
      },
    );
  }

  /// Où va l'enregistrement, et de quoi en changer.
  ///
  /// Le dire **ici**, une fois, plutôt que dans le message qui suit chaque
  /// enregistrement : c'est avant de travailler qu'on veut le savoir.
  Widget _buildAccountTile(BuildContext context) {
    final account = widget.account;
    if (account == null) {
      // Aucun dépôt configuré au lancement : rien à proposer, et rien à
      // expliquer sur un écran de travail.
      return const SizedBox.shrink();
    }

    final signedIn = account.isSignedIn;

    return Column(
      children: <Widget>[
        ListTile(
          leading: Icon(signedIn ? Icons.cloud_done_outlined : Icons.cloud_off),
          title: Text(
            signedIn
                ? 'Dépôt distant : le contenu y est lu et écrit'
                : 'Cet appareil : le contenu y est lu et écrit',
          ),
          subtitle: Text(
            signedIn
                // L'UID est ce que la règle du bucket doit nommer : le montrer
                // évite d'aller le chercher dans la console.
                ? 'Connecté — identifiant ${account.userId}'
                : 'Se connecter pour travailler sur le dépôt.',
          ),
          trailing: signedIn
              ? TextButton(
                  onPressed: () async {
                    await account.signOut();
                    if (mounted) _reload();
                  },
                  child: const Text('Se déconnecter'),
                )
              : const Icon(Icons.chevron_right),
          onTap: signedIn ? null : () => _signIn(account),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
