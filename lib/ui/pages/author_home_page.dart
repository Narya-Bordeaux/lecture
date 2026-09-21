import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/repositories/adventure_repository.dart';
import 'package:grisbie/ui/pages/area_editor_page.dart';

/// Le sommaire de l'outil d'auteur : choisir l'etape dont on cale les zones.
///
/// Une etape sans famille n'y figure pas : il n'y a rien a y poser.
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

          return ListView.separated(
            itemCount: stages.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildTile(stages[index]),
          );
        },
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
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AreaEditorPage(stage: stage),
        ),
      ),
    );
  }
}
