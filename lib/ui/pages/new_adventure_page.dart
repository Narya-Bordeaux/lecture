import 'package:flutter/material.dart';
import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/domain/models/adventure.dart';

/// Commencer une aventure a partir de rien : un titre, un lieu de depart.
///
/// Deux champs, pas davantage. Tout le reste — les trajets, les mots, les
/// illustrations — se construit ensuite dans l'ecran du parcours, ou l'on voit
/// ce qu'on fabrique. Demander plus ici serait un formulaire a remplir avant
/// d'avoir rien vu.
///
/// Renvoie l'aventure neuve, ou `null` si l'auteur renonce.
class NewAdventurePage extends StatefulWidget {
  const NewAdventurePage({super.key});

  @override
  State<NewAdventurePage> createState() => _NewAdventurePageState();
}

class _NewAdventurePageState extends State<NewAdventurePage> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _startName = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _startName.dispose();
    super.dispose();
  }

  bool get _isComplete =>
      _title.text.trim().isNotEmpty && _startName.text.trim().isNotEmpty;

  void _create() {
    Navigator.of(context).pop(
      AdventureBuilder.createAdventure(
        title: _title.text.trim(),
        startName: _startName.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle aventure'),
        actions: <Widget>[
          TextButton(
            onPressed: _isComplete ? _create : null,
            child: const Text('Commencer'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Titre de la journée',
              hintText: 'Grisbie part à la plage',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _startName,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Où commence la journée ?',
              hintText: 'Devant la maison',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text(
            'Les trajets, les mots et les illustrations viendront ensuite, '
            'dans l\'écran du parcours.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Ouvre la page et renvoie l'aventure neuve, si l'auteur en cree une.
Future<Adventure?> askForNewAdventure(BuildContext context) {
  return Navigator.of(context).push<Adventure>(
    MaterialPageRoute<Adventure>(builder: (_) => const NewAdventurePage()),
  );
}
