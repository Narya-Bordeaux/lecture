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
  const AddTripsPage({required this.locationName, super.key});

  /// Le lieu d'ou partent ces trajets, rappele en tete.
  final String locationName;

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
          const SizedBox(height: 24),
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
          const SizedBox(height: 8),
          SegmentedButton<TripKind>(
            segments: const <ButtonSegment<TripKind>>[
              ButtonSegment<TripKind>(
                value: TripKind.ordinary,
                label: Text('Classique'),
                icon: Icon(Icons.place_outlined),
              ),
              ButtonSegment<TripKind>(
                value: TripKind.encounter,
                label: Text('Personnage'),
                icon: Icon(Icons.person_outline),
              ),
            ],
            selected: <TripKind>{_kinds[index]},
            onSelectionChanged: (selection) =>
                setState(() => _kinds[index] = selection.first),
          ),
        ],
      ),
    );
  }
}
