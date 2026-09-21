import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/repositories/adventure_repository.dart';
import 'package:grisbie/ui/pages/area_editor_page.dart';
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
    super.key,
  });

  final AdventureRepository repository;
  final String adventureId;

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
                    builder: (_) => OutlinePage(adventure: adventure),
                  ),
                ),
              ),
              const Divider(height: 1),
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
        builder: (_) => OutlinePage(adventure: fresh),
      ),
    );
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
