import 'package:flutter/material.dart';
import 'package:grisbie/application/adventure_builder.dart';

/// Demande ce qu'on trouve au bout des trajets qu'on ajoute, et combien.
///
/// **La nature d'abord, le nombre ensuite.** Elle decide de ce que l'enfant
/// fera la-bas, alors que le nombre n'est qu'une commodite de saisie : la
/// poser en tete met la question structurante avant la question de detail.
///
/// **Une seule nature par ajout.** Elle valait auparavant trajet par trajet,
/// ce qui repetait trois pavés d'explication sous chaque nom et laissait
/// composer un lot bigarré sans qu'on sache ce qu'on demandait. Cela n'empeche
/// pas un lieu de mener a des natures differentes — l'aventure livree mene de
/// « Devant la maison » a un tri a plusieurs listes et a deux fins — mais cela
/// se fait en plusieurs ajouts, et le rappel « partent deja d'ici » est la
/// pour ca.
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
    this.existingEndings = const <String, String>{},
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

  /// Vrai si **ce lieu-ci** fait trier entre une liste et le reste.
  ///
  /// Un tri unique n'a qu'une sortie : proposer d'en ajouter plusieurs
  /// laisserait croire a un choix que le moteur refuse.
  ///
  /// A ne pas confondre avec le choix [TripKind.singleSort], qui porte sur le
  /// lieu **d'arrivee** : ouvrir trois tris uniques depuis un carrefour est
  /// legitime, chacun ayant sa propre liste du reste.
  final bool allowsOneTripOnly;

  /// Les fins deja ecrites, de leur identifiant vers leur nom.
  ///
  /// Une fin porte un ecran, une illustration et un texte : deux chemins qui
  /// aboutissent au meme endroit doivent partager la meme, sans quoi l'auteur
  /// ecrit deux fois la meme arrivee et les deux finissent par differer.
  ///
  /// Vide, la question ne se pose pas et l'ecran ne la pose pas : un choix
  /// entre une seule possibilite n'est pas un choix.
  final Map<String, String> existingEndings;

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

  /// La fin deja ecrite que chaque trajet rejoint, nulle pour en creer une.
  ///
  /// Parallele a [_names] : la nature vaut pour tout le lot, la destination se
  /// choisit trajet par trajet.
  final List<String?> _destinations = <String?>[null];

  /// La nature commune aux trajets de cet ajout.
  TripKind _kind = TripKind.ordinary;

  /// Vrai quand il y a une fin existante a proposer.
  bool get _offersEndings =>
      _kind == TripKind.ending && widget.existingEndings.isNotEmpty;

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
        _destinations.add(null);
      }
      while (_names.length > count) {
        _names.removeLast().dispose();
        _destinations.removeLast();
      }
    });
  }

  void _setKind(TripKind kind) {
    setState(() {
      _kind = kind;
      // Une destination choisie pour une fin n'a aucun sens sur un trajet
      // devenu ordinaire : elle le renverrait vers un lieu deja clos.
      if (kind != TripKind.ending) {
        _destinations.fillRange(0, _destinations.length, null);
      }
    });
  }

  /// Choisit la fin rejointe, et propose son nom tant que rien n'est saisi.
  ///
  /// Sans cette proposition, « Créer » reste eteint sans qu'on voie pourquoi.
  /// Le nom reste modifiable : c'est ce que l'enfant lira sur la zone de
  /// depot, et ce n'est pas forcement le nom du lieu.
  void _setDestination(int index, String? stageId) {
    setState(() {
      _destinations[index] = stageId;
      if (stageId != null && _names[index].text.trim().isEmpty) {
        _names[index].text = widget.existingEndings[stageId] ?? '';
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
      trips.add(NewTrip(
        name: name,
        kind: _kind,
        existingStageId: _offersEndings ? _destinations[index] : null,
      ));
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
          _buildKindChoice(context),
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
            _buildName(index),
        ],
      ),
    );
  }

  /// La question structurante, posee une fois pour tout le lot.
  Widget _buildKindChoice(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Qu\'y a-t-il au bout de ces trajets ?'),
        const SizedBox(height: 8),
        // Trois choix structurels, et non trois façons d'habiller un lieu :
        // ils décident de ce que l'enfant fera là-bas. Une liste déroulante
        // les cacherait ; chacun s'explique donc en une ligne.
        RadioGroup<TripKind>(
          groupValue: _kind,
          onChanged: (chosen) => _setKind(chosen!),
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
                    'tout le reste. Le lieu d\'arrivée n\'a qu\'une sortie.',
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
        const SizedBox(height: 4),
        // Dit du meme coup ce que l'ecran ne fait pas, et comment l'obtenir :
        // un lieu peut bel et bien mener a des natures differentes.
        Text(
          'Tous les trajets ajoutés ici seront de cette sorte. Pour en '
          'mélanger, revenez ensuite ajouter les autres.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildName(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
          if (_offersEndings) _buildEndingChoice(index),
        ],
      ),
    );
  }

  /// Ou mene ce trajet : vers une fin neuve, ou vers une fin deja ecrite.
  ///
  /// La destination se choisit trajet par trajet, contrairement a la nature :
  /// d'un meme carrefour, un chemin peut rejoindre la plage et l'autre finir
  /// sur une arrivee qui reste a ecrire.
  Widget _buildEndingChoice(int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: DropdownButton<String?>(
        value: _destinations[index],
        isExpanded: true,
        onChanged: (chosen) => _setDestination(index, chosen),
        items: <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(
            child: Text('Une nouvelle fin'),
          ),
          for (final ending in widget.existingEndings.entries)
            DropdownMenuItem<String?>(
              value: ending.key,
              child: Text(ending.value),
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
