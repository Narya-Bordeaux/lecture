import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/repositories/adventure_repository.dart';
import 'package:grisbie/domain/repositories/author_account.dart';
import 'package:grisbie/domain/repositories/picture_library.dart';
import 'package:grisbie/ui/pages/area_editor_page.dart';
import 'package:grisbie/ui/pages/author_sign_in_page.dart';
import 'package:grisbie/ui/pages/new_adventure_page.dart';
import 'package:grisbie/ui/pages/outline_page.dart';

/// Le sommaire de l'outil d'auteur.
///
/// Deux entrees pour creer, puis la liste des etapes du contenu livre dont on
/// cale les zones. Une etape sans famille n'y figure pas : il n'y a rien a y
/// poser.
class AuthorHomePage extends StatefulWidget {
  const AuthorHomePage({
    required this.repository,
    required this.adventureId,
    this.pictures,
    this.onSave,
    this.account,
    super.key,
  });

  final AdventureRepository repository;
  final String adventureId;

  /// De quoi choisir une illustration dans l'appareil.
  ///
  /// Injectee ici et transmise de proche en proche : aucun ecran ne la
  /// construit, et les tests en passent une fausse — ou aucune.
  final PictureLibrary? pictures;

  /// Ce qui ecrit une aventure. Nul, l'ecran du parcours ne le propose pas.
  ///
  /// C'est le point d'entree qui sait ou l'on ecrit : un dossier sur un
  /// appareil, le telechargement d'un navigateur.
  final Future<List<String>> Function(Adventure adventure)? onSave;

  /// Le compte de l'auteur sur le depot distant.
  ///
  /// Nul quand le lancement n'a pas configure de depot : l'outil enregistre
  /// alors sur l'appareil, et n'en parle pas.
  final AuthorAccount? account;

  @override
  State<AuthorHomePage> createState() => _AuthorHomePageState();
}

class _AuthorHomePageState extends State<AuthorHomePage> {
  late Future<Adventure> _adventure;

  @override
  void initState() {
    super.initState();
    _adventure = widget.repository.loadAdventure(widget.adventureId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calage des zones')),
      body: FutureBuilder<Adventure>(
        future: _adventure,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Contenu illisible :\n\n${snapshot.error}'),
            );
          }
          final adventure = snapshot.data;
          if (adventure == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final stages = adventure.stages.values
              .where((stage) => stage.families.isNotEmpty)
              .toList(growable: false);

          return Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Nouvelle aventure'),
                subtitle: const Text('Partir d\'une page blanche'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _startNewAdventure(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.account_tree_outlined),
                title: const Text('Construire le parcours'),
                subtitle: Text('« ${adventure.title} »'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<Adventure>(
                    builder: (_) => OutlinePage(
                      adventure: adventure,
                      pictures: widget.pictures,
                      onSave: widget.onSave,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildAccountTile(context),
              Expanded(
                child: ListView.separated(
                  itemCount: stages.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) => _buildTile(stages[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Cree une aventure neuve et enchaine aussitot sur son parcours.
  ///
  /// Rien ne l'enregistre encore : elle vit le temps de la session.
  Future<void> _startNewAdventure(BuildContext context) async {
    final fresh = await askForNewAdventure(context);
    if (fresh == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<Adventure>(
        builder: (_) => OutlinePage(
          adventure: fresh,
          pictures: widget.pictures,
          onSave: widget.onSave,
        ),
      ),
    );
  }

  /// Ou va l'enregistrement, et de quoi en changer.
  ///
  /// Le dire **ici**, une fois, plutot que dans le message qui suit chaque
  /// enregistrement : c'est avant de travailler qu'on veut le savoir.
  Widget _buildAccountTile(BuildContext context) {
    final account = widget.account;
    if (account == null) {
      // Aucun depot configure au lancement : rien a proposer, et rien a
      // expliquer sur un ecran de travail.
      return const SizedBox.shrink();
    }

    final signedIn = account.isSignedIn;

    return Column(
      children: <Widget>[
        ListTile(
          leading: Icon(signedIn ? Icons.cloud_done_outlined : Icons.cloud_off),
          title: Text(
            signedIn
                ? 'Enregistrement : le dépôt distant'
                : 'Enregistrement : cet appareil',
          ),
          subtitle: Text(
            signedIn
                // L'UID est ce que la regle du bucket doit nommer : le montrer
                // evite d'aller le chercher dans la console.
                ? 'Connecté — identifiant ${account.userId}'
                : 'Se connecter pour déposer sur le dépôt.',
          ),
          trailing: signedIn
              ? TextButton(
                  onPressed: () async {
                    await account.signOut();
                    if (mounted) setState(() {});
                  },
                  child: const Text('Se déconnecter'),
                )
              : const Icon(Icons.chevron_right),
          onTap: signedIn ? null : () => _signIn(context, account),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _signIn(BuildContext context, AuthorAccount account) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AuthorSignInPage(account: account),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _buildTile(Stage stage) {
    final placed = stage.families.where((family) => family.area != null).length;
    final total = stage.families.length;
    final illustrated = stage.backgroundAsset != null;

    return ListTile(
      title: Text(stage.locationName),
      subtitle: Text(
        '$placed zone(s) posée(s) sur $total'
        '${illustrated ? '' : ' — pas d\'illustration'}',
      ),
      trailing: const Icon(Icons.open_in_full),
      // Le calage sur le contenu livre : il rend l'etape calee, mais rien ici
      // ne la garde — c'est « Copier » qui sert, le JSON etant recolle a la
      // main dans le fichier d'aventure. Passer par « Construire le parcours »
      // garde le calage en memoire jusqu'a la fin de la session.
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<Stage>(
          builder: (_) => AreaEditorPage(stage: stage),
        ),
      ),
    );
  }
}
