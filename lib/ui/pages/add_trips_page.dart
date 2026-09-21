import 'package:flutter/material.dart';
import 'package:grisbie/application/adventure_builder.dart';

/// Demande combien de trajets partent d'un lieu, et ce qu'ils sont.
///
/// Une page plutot qu'une boite de dialogue : on y tape plusieurs noms au
/// clavier du telephone, et une boite qui remonte au-dessus du clavier laisse
/// peu de place pour relire ce qu'on ecrit.
///
/// Renvoie les trajets demandes, ou `null` si l'auteur renonce.
class AddTripsPage extends StatefulWidget {
  const AddTripsPage({
    required this.locationName,
    this.existingTrips = const <String>[],
    this.allowsOneTripOnly = false,
    super.key,
  });

  /// Le lieu d'ou partent ces trajets, rappele en tete.
  final String locationName;

  /// Ce qui part deja d'ici, rappele pour qu'on ajoute au lieu de recommencer.
  ///
  /// Sans ce rappel, ouvrir l'ajout sur un lieu qui a deja trois directions
  /// presente une page vide, et laisse croire qu'elles ont disparu.
  final List<String> existingTrips;

  /// Vrai si ce lieu fait trier entre une liste et le reste.
  ///
  /// Un tri unique n'a qu'une sortie : proposer d'en ajouter plusieurs
  /// laisserait croire a un choix que le moteur refuse.
  final bool allowsOneTripOnly;

  /// Au-dela, l'etape proposerait trop de directions a un enfant de six ans,
  /// et les zones de depot ne tiendraient plus sur l'illustration.
  static const int maxTrips = 6;

  @override
  State<AddTripsPage> createState() => _AddTripsPageState();
}

class _AddTripsPageState extends State<AddTripsPage> {
  final List<TextEditingController> _names = <TextEditingController>[
    TextEditingController(),
  ];
  final List<TripKind> _kinds = <TripKind>[TripKind.ordinary];

  @override
  void dispose() {
    for (final controller in _names) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setCount(int count) {
    setState(() {
      while (_names.length < count) {
        _names.add(TextEditingController());
        _kinds.add(TripKind.ordinary);
      }
      while (_names.length > count) {
        _names.removeLast().dispose();
        _kinds.removeLast();
      }
    });
  }

  /// Les trajets nommes. Un nom vide ne cree rien : mieux vaut un trajet de
  /// moins qu'un lieu appele « lieu ».
  List<NewTrip> get _trips {
    final trips = <NewTrip>[];
    for (var index = 0; index < _names.length; index++) {
      final name = _names[index].text.trim();
      if (name.isEmpty) continue;
      trips.add(NewTrip(name: name, kind: _kinds[index]));
    }
    return trips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter des trajets'),
        actions: <Widget>[
          TextButton(
            onPressed:
                _trips.isEmpty ? null : () => Navigator.of(context).pop(_trips),
            child: const Text('Créer'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Depuis « ${widget.locationName} »',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (widget.existingTrips.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Partent déjà d\'ici : ${widget.existingTrips.join(', ')}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Ce que vous ajoutez ici s\'ajoute à ces trajets.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          if (widget.allowsOneTripOnly)
            Text(
              'Ici, l\'enfant trie entre une liste et le reste : ce lieu n\'a '
              'qu\'une seule sortie.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else ...<Widget>[
            const Text('Combien de trajets partent d\'ici ?'),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: <ButtonSegment<int>>[
                for (var count = 1; count <= AddTripsPage.maxTrips; count++)
                  ButtonSegment<int>(value: count, label: Text('$count')),
              ],
              selected: <int>{_names.length},
              onSelectionChanged: (selection) => _setCount(selection.first),
            ),
          ],
          const SizedBox(height: 24),
          for (var index = 0; index < _names.length; index++)
            _buildTrip(index),
        ],
      ),
    );
  }

  Widget _buildTrip(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _names[index],
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Trajet ${index + 1}',
              hintText: 'En bus, La gare, Le guichetier…',
              border: const OutlineInputBorder(),
            ),
            // Le bouton « Créer » s'active des qu'un nom est saisi.
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          // Trois choix structurels, et non trois façons d'habiller un lieu :
          // ils décident de ce que l'enfant fera là-bas. Une liste déroulante
          // les cacherait ; chacun s'explique donc en une ligne.
          RadioGroup<TripKind>(
            groupValue: _kinds[index],
            onChanged: (chosen) => setState(() => _kinds[index] = chosen!),
            child: const Column(
              children: <Widget>[
                _KindChoice(
                  kind: TripKind.ordinary,
                  icon: Icons.dashboard_outlined,
                  title: 'Plusieurs listes',
                  explanation: 'L\'enfant trie entre plusieurs familles, et le '
                      'lieu pourra ouvrir plusieurs chemins.',
                ),
                _KindChoice(
                  kind: TripKind.singleSort,
                  icon: Icons.filter_alt_outlined,
                  title: 'Tri unique',
                  explanation: 'L\'enfant trie entre ce qui est du thème et '
                      'tout le reste. Une seule sortie.',
                ),
                _KindChoice(
                  kind: TripKind.ending,
                  icon: Icons.flag_outlined,
                  title: 'Une fin',
                  explanation: 'La journée s\'arrête là. Rien n\'en repart.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Un des trois choix structurels, avec ce qu'il change pour l'enfant.
class _KindChoice extends StatelessWidget {
  const _KindChoice({
    required this.kind,
    required this.icon,
    required this.title,
    required this.explanation,
  });

  final TripKind kind;
  final IconData icon;
  final String title;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<TripKind>(
      value: kind,
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      subtitle: Text(
        explanation,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
