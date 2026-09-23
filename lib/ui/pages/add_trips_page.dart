import 'package:flutter/material.dart';
import 'package:grisbie/application/adventure_builder.dart';

/// Nomme les trajets qui partent d'un lieu, et les lieux qu'ils atteignent.
///
/// **La nature du lieu ne se choisit plus ici.** Elle se choisit sur sa carte,
/// en repondant a « que fait l'enfant ici ? » : ranger dans plusieurs listes,
/// faire un tri unique, ou lire la fin. Cette page ne sert qu'ensuite, a
/// nommer les sorties — plusieurs pour un lieu a listes, une seule pour un tri
/// unique. Les lieux atteints naissent a definir, et se definiront sur leur
/// propre carte.
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
    this.existingPlaces = const <String, String>{},
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
  /// Un tri unique n'a qu'une sortie, celle que le theme ouvre : proposer
  /// d'en ajouter plusieurs laisserait croire a un choix que le moteur refuse.
  /// Le champ unique nomme alors le theme.
  final bool allowsOneTripOnly;

  /// Les lieux deja ecrits qu'un trajet peut rejoindre, de leur identifiant
  /// vers leur nom.
  ///
  /// D'abord pour les fins : deux chemins qui aboutissent au meme endroit
  /// doivent partager la meme, sans quoi l'auteur ecrit deux fois la meme
  /// arrivee. Mais tout lieu est propose : revenir en arriere est permis, et
  /// la boucle ainsi creee est signalee, a verifier, sans etre interdite.
  ///
  /// Vide, la question ne se pose pas et l'ecran ne la pose pas : un choix
  /// entre une seule possibilite n'est pas un choix.
  final Map<String, String> existingPlaces;

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

  /// Le nom du lieu atteint, parallele a [_names].
  ///
  /// **Deux champs, parce que ce sont deux choses** : « En bus » est ce que
  /// l'enfant lit sur la zone de depot, « La gare » est le lieu ou il arrive,
  /// avec son illustration et son recit. Un seul champ baptisait le lieu du
  /// nom du trajet, ce qui rendait l'outil incapable d'ecrire le contenu
  /// livre — et apprenait a l'auteur une regle fausse.
  final List<TextEditingController> _locations = <TextEditingController>[
    TextEditingController(),
  ];

  /// Les lieux dont l'auteur a saisi le nom lui-meme.
  ///
  /// Tant qu'il n'y touche pas, le lieu suit le trajet : c'est le cas courant,
  /// et saisir deux fois la meme chose serait une corvee. Des qu'il l'ecrit,
  /// le champ se detache — voir son nom disparaitre en corrigeant une faute
  /// de frappe dans le trajet serait incomprehensible.
  final List<bool> _namedLocations = <bool>[false];

  /// Le lieu deja ecrit que chaque trajet rejoint, nul pour un lieu neuf.
  ///
  /// Parallele a [_names] : d'un meme carrefour, un chemin peut rejoindre la
  /// plage et l'autre mener a un lieu qui reste a ecrire.
  final List<String?> _destinations = <String?>[null];

  /// Vrai quand il y a un lieu existant a proposer.
  ///
  /// Vide, la question ne se pose pas : un choix entre une seule possibilite
  /// n'est pas un choix.
  bool get _offersPlaces => widget.existingPlaces.isNotEmpty;

  @override
  void dispose() {
    for (final controller in <TextEditingController>[..._names, ..._locations]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setCount(int count) {
    setState(() {
      while (_names.length < count) {
        _names.add(TextEditingController());
        _locations.add(TextEditingController());
        _namedLocations.add(false);
        _destinations.add(null);
      }
      while (_names.length > count) {
        _names.removeLast().dispose();
        _locations.removeLast().dispose();
        _namedLocations.removeLast();
        _destinations.removeLast();
      }
    });
  }

  /// Le trajet vient d'etre renomme : le lieu suit, sauf s'il est ecrit.
  void _setTripName(int index) {
    setState(() {
      if (!_namedLocations[index]) {
        _locations[index].text = _names[index].text;
      }
    });
  }

  /// Choisit le lieu rejoint, et propose son nom tant que rien n'est saisi.
  ///
  /// Sans cette proposition, « Créer » reste eteint sans qu'on voie pourquoi.
  /// Le nom reste modifiable : c'est ce que l'enfant lira sur la zone de
  /// depot, et ce n'est pas forcement le nom du lieu.
  void _setDestination(int index, String? stageId) {
    setState(() {
      _destinations[index] = stageId;
      if (stageId != null && _names[index].text.trim().isEmpty) {
        _names[index].text = widget.existingPlaces[stageId] ?? '';
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
        locationName: _locations[index].text.trim(),
        existingStageId: _offersPlaces ? _destinations[index] : null,
      ));
    }
    return trips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.allowsOneTripOnly ? 'Tri unique' : 'Ajouter des trajets',
        ),
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
              'Ici, l\'enfant trie entre une liste et tout le reste. Le lieu '
              'n\'a qu\'une sortie : celle que le thème ouvre.',
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

  Widget _buildName(int index) {
    // Le lieu existe deja : son nom n'est pas a saisir, et le proposer
    // laisserait croire qu'on peut le renommer d'ici — alors qu'il est
    // partage avec les autres chemins qui y aboutissent.
    final joinsExisting = _offersPlaces && _destinations[index] != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            key: Key('trip-name-$index'),
            controller: _names[index],
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: widget.allowsOneTripOnly
                  ? 'Le thème'
                  : 'Trajet ${index + 1}',
              hintText: widget.allowsOneTripOnly
                  ? 'Ce qui se mange, Ce qui roule…'
                  : 'En bus, À pied, Prendre le train…',
              helperText: widget.allowsOneTripOnly
                  ? 'Ce que l\'enfant lit sur la zone du thème. La remplir '
                      'ouvre la sortie.'
                  : 'Ce que l\'enfant lit sur la zone de dépôt.',
              border: const OutlineInputBorder(),
            ),
            // Le bouton « Créer » s'active des qu'un nom est saisi, et le nom
            // du lieu suit tant que l'auteur ne l'a pas ecrit lui-meme.
            onChanged: (_) => _setTripName(index),
          ),
          if (_offersPlaces) _buildPlaceChoice(index),
          if (!joinsExisting) ...<Widget>[
            const SizedBox(height: 12),
            TextField(
              key: Key('location-name-$index'),
              controller: _locations[index],
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Le lieu où ça mène',
                hintText: 'La gare, La plage, Le garage…',
                helperText: 'Son titre, son illustration, son récit '
                    'd\'arrivée.',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _namedLocations[index] = true),
            ),
          ],
        ],
      ),
    );
  }

  /// Ou mene ce trajet : vers un lieu neuf, ou vers un lieu deja ecrit.
  ///
  /// Tout lieu est propose. Rejoindre une fin est le cas courant ; revenir en
  /// arriere cree une boucle, que le parcours signale a verifier.
  Widget _buildPlaceChoice(int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: DropdownButton<String?>(
        value: _destinations[index],
        isExpanded: true,
        onChanged: (chosen) => _setDestination(index, chosen),
        items: <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(
            child: Text('Un nouveau lieu'),
          ),
          for (final place in widget.existingPlaces.entries)
            DropdownMenuItem<String?>(
              value: place.key,
              child: Text('Rejoindre « ${place.value} »'),
            ),
        ],
      ),
    );
  }
}
