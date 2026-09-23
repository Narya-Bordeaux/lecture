import 'package:flutter/material.dart';
import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/ui/pages/add_trips_page.dart';

/// La structure d'un lieu : ce que l'enfant y fait, et les trajets qui en
/// partent.
///
/// Ouverte en touchant la ligne « Plusieurs listes », « Tri unique » ou
/// « Fin » d'une carte. C'est le troisieme geste de la carte, a cote du titre
/// (ce que le lieu montre) et des trajets (leurs listes de mots) : **revenir
/// sur un choix de circuit**, qu'aucun ecran ne permettait jusque-la.
///
/// Changer de nature garde ce qui peut l'etre, et chaque retrait se confirme
/// en nommant ce qui part. **Aucun lieu ne disparait en passant** : celui que
/// plus rien n'atteint reste sur le parcours, marque « Aucun chemin ne mene
/// ici », jusqu'a ce que l'auteur le supprime depuis sa carte.
///
/// La page ne decide rien : elle passe les gestes a [AdventureBuilder] et
/// rend l'aventure modifiee par « Garder ».
class StageStructurePage extends StatefulWidget {
  const StageStructurePage({
    required this.adventure,
    required this.stageId,
    super.key,
  });

  final Adventure adventure;
  final String stageId;

  @override
  State<StageStructurePage> createState() => _StageStructurePageState();
}

class _StageStructurePageState extends State<StageStructurePage> {
  late Adventure _adventure = widget.adventure;

  Stage get _stage => _adventure.findStage(widget.stageId)!;

  AdventureBuilder get _builder => AdventureBuilder(_adventure);

  void _apply(Adventure Function(AdventureBuilder builder) change) {
    try {
      final next = change(_builder);
      setState(() => _adventure = next);
    } on StateError catch (error) {
      _tell(error.message);
    } on ArgumentError catch (error) {
      _tell('${error.message}');
    }
  }

  void _tell(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Demande confirmation avant un geste qui retire quelque chose.
  Future<bool> _confirm(String title, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Les noms des trajets qui partiraient, pour les dire avant d'agir.
  String _named(Iterable<WordFamily> families) {
    return families.map((family) => '« ${family.label} »').join(', ');
  }

  static const String _keptNote =
      'Les lieux où ils menaient restent sur le parcours ; les listes déjà '
      'enregistrées restent réutilisables.';

  @override
  Widget build(BuildContext context) {
    final stage = _stage;

    return Scaffold(
      appBar: AppBar(
        title: Text(stage.locationName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Fermer sans garder',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(_adventure),
            child: const Text('Garder'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Ce que l\'enfant fait ici',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            _natureLabel(stage.nature),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _conversions(stage),
          ),
          if (stage.families.isNotEmpty) ...<Widget>[
            const SizedBox(height: 24),
            Text('Les trajets', style: Theme.of(context).textTheme.labelLarge),
            for (final family in stage.families) _buildTrip(family),
          ],
          for (final issue in _warnings()) _WarningLine(issue: issue),
        ],
      ),
    );
  }

  static String _natureLabel(StageNature nature) {
    return switch (nature) {
      StageNature.undefined => 'À définir',
      StageNature.sorting => 'Plusieurs listes',
      StageNature.singleSort => 'Tri unique',
      StageNature.ending => 'Une fin : du texte, pas de jeu',
    };
  }

  /// Les changements de nature possibles depuis celle-ci.
  List<Widget> _conversions(Stage stage) {
    switch (stage.nature) {
      case StageNature.undefined:
        // Les memes trois reponses que sur la carte : un lieu qu'on vient de
        // rouvrir ne doit pas renvoyer ailleurs pour etre redefini.
        return <Widget>[
          OutlinedButton.icon(
            onPressed: () => _addTrips(singleExit: false),
            icon: const Icon(Icons.dashboard_outlined, size: 18),
            label: const Text('Plusieurs listes'),
          ),
          OutlinedButton.icon(
            onPressed: _defineSingleSort,
            icon: const Icon(Icons.filter_alt_outlined, size: 18),
            label: const Text('Tri unique'),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                _apply((builder) => builder.defineAsEnding(widget.stageId)),
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('Une fin'),
          ),
        ];

      case StageNature.sorting:
        return <Widget>[
          OutlinedButton.icon(
            onPressed: () => _addTrips(singleExit: false),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter des trajets'),
          ),
          OutlinedButton.icon(
            onPressed: _toSingleSort,
            icon: const Icon(Icons.filter_alt_outlined, size: 18),
            label: const Text('En faire un tri unique'),
          ),
          OutlinedButton.icon(
            onPressed: _toEnding,
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('En faire une fin'),
          ),
        ];

      case StageNature.singleSort:
        final hasExit = stage.families.any((f) => f.leadsSomewhere);
        return <Widget>[
          if (!hasExit)
            OutlinedButton.icon(
              onPressed: () => _addTrips(singleExit: true),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter la sortie'),
            ),
          OutlinedButton.icon(
            onPressed: _toSorting,
            icon: const Icon(Icons.dashboard_outlined, size: 18),
            label: const Text('Revenir à plusieurs listes'),
          ),
          OutlinedButton.icon(
            onPressed: _toEnding,
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('En faire une fin'),
          ),
        ];

      case StageNature.ending:
        return <Widget>[
          OutlinedButton.icon(
            onPressed: () => _apply((builder) => builder.reopen(widget.stageId)),
            icon: const Icon(Icons.lock_open_outlined, size: 18),
            label: const Text('Rouvrir ce lieu'),
          ),
        ];
    }
  }

  /// Demande des trajets a nommer, comme depuis la carte.
  Future<List<NewTrip>?> _askTrips({required bool singleExit}) async {
    final trips = await Navigator.of(context).push<List<NewTrip>>(
      MaterialPageRoute<List<NewTrip>>(
        builder: (_) => AddTripsPage(
          locationName: _stage.locationName,
          allowsOneTripOnly: singleExit,
          existingTrips: _stage.families
              .where((family) => family.leadsSomewhere)
              .map((family) => family.label)
              .toList(growable: false),
          existingPlaces: <String, String>{
            for (final stage in _adventure.stages.values)
              if (stage.id != widget.stageId) stage.id: stage.locationName,
          },
        ),
      ),
    );
    if (trips == null || trips.isEmpty) return null;
    return trips;
  }

  /// Ajoute des trajets : fait d'un lieu a definir un lieu a plusieurs
  /// listes, en prolonge un, ou pose la sortie d'un tri unique.
  Future<void> _addTrips({required bool singleExit}) async {
    final trips = await _askTrips(singleExit: singleExit);
    if (trips == null) return;
    _apply((builder) => builder.addTrips(widget.stageId, trips));
  }

  Future<void> _defineSingleSort() async {
    final trips = await _askTrips(singleExit: true);
    if (trips == null) return;
    _apply(
      (builder) => builder.defineAsSingleSort(widget.stageId, trips.first),
    );
  }

  /// Plusieurs listes → tri unique : l'auteur choisit le trajet du theme.
  Future<void> _toSingleSort() async {
    final trips = _stage.families.where((f) => f.leadsSomewhere).toList();
    final themeId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Quel trajet devient le thème ?'),
        children: <Widget>[
          for (final trip in trips)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(trip.id),
              child: Text(trip.label),
            ),
        ],
      ),
    );
    if (themeId == null) return;

    final removed = trips.where((trip) => trip.id != themeId);
    if (removed.isNotEmpty &&
        !await _confirm(
          'En faire un tri unique',
          'Ces trajets seront retirés : ${_named(removed)}. $_keptNote',
        )) {
      return;
    }

    _apply(
      (builder) =>
          builder.convertToSingleSort(widget.stageId, themeFamilyId: themeId),
    );
  }

  Future<void> _toSorting() async {
    final rest = _stage.families.where((f) => !f.leadsSomewhere);
    if (!await _confirm(
      'Revenir à plusieurs listes',
      'Le panier ${_named(rest)} sera retiré ; le thème devient un trajet '
          'ordinaire, et vous pourrez en ajouter d\'autres.',
    )) {
      return;
    }
    _apply((builder) => builder.convertToSorting(widget.stageId));
  }

  Future<void> _toEnding() async {
    if (!await _confirm(
      'En faire une fin',
      'Tous les trajets seront retirés : ${_named(_stage.families)}. '
          '$_keptNote',
    )) {
      return;
    }
    _apply((builder) => builder.convertToEnding(widget.stageId));
  }

  Widget _buildTrip(WordFamily family) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    family.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Renommer « ${family.label} »',
                  onPressed: () => _rename(family),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Retirer « ${family.label} »',
                  onPressed: () => _remove(family),
                ),
              ],
            ),
            if (family.leadsSomewhere)
              _destinationChoice(family)
            else
              Text(
                'Le panier « autre » : il ne mène nulle part.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  /// Ou mene ce trajet : n'importe quel lieu deja ecrit, lui compris.
  ///
  /// Revenir en arriere est permis ; la boucle est alors signalee, a
  /// verifier, sans rien interdire.
  Widget _destinationChoice(WordFamily family) {
    final current = family.destinationStageId;
    final known = _adventure.stages.containsKey(current);

    return Row(
      children: <Widget>[
        const Icon(Icons.subdirectory_arrow_right, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButton<String>(
            key: Key('destination-${family.id}'),
            isExpanded: true,
            value: known ? current : null,
            hint: const Text('Un lieu qui n\'existe pas encore'),
            items: <DropdownMenuItem<String>>[
              for (final stage in _adventure.stages.values)
                DropdownMenuItem<String>(
                  value: stage.id,
                  child: Text(
                    stage.id == widget.stageId
                        ? '${stage.locationName} (ce lieu même)'
                        : stage.locationName,
                  ),
                ),
            ],
            onChanged: (chosen) {
              if (chosen == null || chosen == current) return;
              _apply(
                (builder) =>
                    builder.redirectTrip(widget.stageId, family.id, chosen),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _rename(WordFamily family) async {
    final label = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(initial: family.label),
    );
    if (label == null) return;
    _apply((builder) => builder.renameTrip(widget.stageId, family.id, label));
  }

  Future<void> _remove(WordFamily family) async {
    if (!await _confirm(
      'Retirer « ${family.label} »',
      family.leadsSomewhere
          ? 'Le lieu où il menait reste sur le parcours ; sa liste, si elle '
                'est enregistrée, reste réutilisable.'
          : 'Le lieu cessera d\'être un tri unique.',
    )) {
      return;
    }
    _apply((builder) => builder.removeTrip(widget.stageId, family.id));
  }

  /// Les boucles qui passent par ce lieu : a verifier, jamais interdites.
  List<ContentIssue> _warnings() {
    return _adventure
        .validate()
        .where(
          (issue) =>
              issue.severity == IssueSeverity.warning &&
              issue.stageId == widget.stageId,
        )
        .toList(growable: false);
  }
}

/// Le nouveau nom d'un trajet. A etat : le champ doit survivre a l'animation
/// de fermeture de la boite.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _text =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renommer le trajet'),
      content: TextField(
        key: const Key('rename-trip'),
        controller: _text,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Son nom',
          helperText: 'Ce que l\'enfant lit sur la zone de dépôt.',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_text.text),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

class _WarningLine extends StatelessWidget {
  const _WarningLine({required this.issue});

  final ContentIssue issue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.loop, size: 16, color: Colors.orange.shade800),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              issue.message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
