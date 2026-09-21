import 'package:flutter/material.dart';
import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/application/adventure_outline.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/ui/pages/add_trips_page.dart';

/// Construire le parcours d'une aventure, point par point.
///
/// Reprend la forme du croquis papier de l'auteur : un point porte une lettre,
/// les trajets qui en partent se lisent en dessous, et chacun mene a un point
/// qui se deploie a son tour plus bas.
///
/// L'aventure ne quitte pas la memoire : cette page la modifie et la rend a
/// l'appelant. L'enregistrement est un autre sujet, et un autre ecran.
class OutlinePage extends StatefulWidget {
  const OutlinePage({required this.adventure, super.key});

  final Adventure adventure;

  @override
  State<OutlinePage> createState() => _OutlinePageState();
}

class _OutlinePageState extends State<OutlinePage> {
  late Adventure _adventure = widget.adventure;

  Future<void> _addTrips(String stageId, String locationName) async {
    final trips = await Navigator.of(context).push<List<NewTrip>>(
      MaterialPageRoute<List<NewTrip>>(
        builder: (_) => AddTripsPage(locationName: locationName),
      ),
    );
    if (trips == null || trips.isEmpty) return;

    setState(() {
      _adventure = AdventureBuilder(_adventure).addTrips(stageId, trips);
    });
  }

  @override
  Widget build(BuildContext context) {
    final outline = AdventureOutline.of(_adventure);
    final issues = _adventure.validate();

    return Scaffold(
      appBar: AppBar(
        title: Text(_adventure.title),
        // Rendre l'aventure modifiee a l'appelant : rien ne la relit ailleurs.
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(_adventure),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: <Widget>[
          _IssueSummary(issues: issues),
          for (final block in outline.blocks)
            _BlockCard(
              block: block,
              issues: issues.where((i) => i.stageId == block.stageId).toList(),
              onAddTrips: _addTrips,
            ),
          _UnwrittenPlaces(
            outline: outline,
            adventure: _adventure,
            onAddTrips: _addTrips,
          ),
        ],
      ),
    );
  }
}

/// Ce qu'il reste a faire, et ce qui est a corriger, en tete d'ecran.
///
/// Les deux ne se melangent pas : une aventure en cours d'ecriture est
/// toujours incomplete, et l'annoncer comme une faute apprendrait a ignorer
/// l'ecran.
class _IssueSummary extends StatelessWidget {
  const _IssueSummary({required this.issues});

  final List<ContentIssue> issues;

  @override
  Widget build(BuildContext context) {
    final wrong =
        issues.where((i) => i.severity == IssueSeverity.wrong).length;
    final incomplete = issues.length - wrong;

    if (issues.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text('Cette aventure est jouable.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: <Widget>[
          if (wrong > 0) ...<Widget>[
            Icon(Icons.error_outline,
                size: 18, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 4),
            Text('$wrong à corriger',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(width: 16),
          ],
          if (incomplete > 0) ...<Widget>[
            const Icon(Icons.pending_outlined, size: 18),
            const SizedBox(width: 4),
            Text('$incomplete à finir'),
          ],
        ],
      ),
    );
  }
}

/// Un point du parcours, avec les trajets qui en partent.
class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.block,
    required this.issues,
    required this.onAddTrips,
  });

  final OutlineBlock block;
  final List<ContentIssue> issues;
  final void Function(String stageId, String locationName) onAddTrips;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _Letter(block.letter),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    block.locationName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (block.isEncounter) const Icon(Icons.person_outline, size: 18),
                // La case du croquis : le recit qui accompagne le depart.
                Icon(
                  block.hasTransitionText
                      ? Icons.check_box_outlined
                      : Icons.check_box_outline_blank,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final trip in block.trips) _buildTrip(context, trip),
            for (final issue in issues) _IssueLine(issue: issue),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onAddTrips(block.stageId, block.locationName),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrip(BuildContext context, OutlineTrip trip) {
    final destination = trip.destinationStageId;

    return InkWell(
      // Cliquer un trajet, c'est ajouter la suite depuis son arrivee. Un
      // classeur sans issue ne mene nulle part : il n'est pas cliquable.
      onTap: destination == null ? null : () => onAddTrips(destination, trip.label),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 8),
            const Icon(Icons.subdirectory_arrow_right, size: 16),
            const SizedBox(width: 8),
            if (trip.destinationLetter != null) ...<Widget>[
              _Letter(trip.destinationLetter!, small: true),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(trip.label)),
            if (trip.leadsToEncounter)
              const Icon(Icons.person_outline, size: 16),
            if (trip.leadsToEnding) const Icon(Icons.flag_outlined, size: 16),
            if (destination == null)
              Text(
                'sans issue',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

/// Les lieux qu'aucun chemin n'atteint, montres a part plutot que disparus.
class _UnwrittenPlaces extends StatelessWidget {
  const _UnwrittenPlaces({
    required this.outline,
    required this.adventure,
    required this.onAddTrips,
  });

  final AdventureOutline outline;
  final Adventure adventure;
  final void Function(String stageId, String locationName) onAddTrips;

  @override
  Widget build(BuildContext context) {
    if (outline.detachedStageIds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 16),
        Text(
          'Lieux non reliés',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Aucun chemin n\'y mène : l\'enfant ne les verra jamais.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        for (final stageId in outline.detachedStageIds)
          ListTile(
            leading: _Letter(outline.letterOf(stageId)!),
            title: Text(adventure.findStage(stageId)!.locationName),
            trailing: const Icon(Icons.add),
            onTap: () => onAddTrips(
              stageId,
              adventure.findStage(stageId)!.locationName,
            ),
          ),
      ],
    );
  }
}

/// Une anomalie, dite en clair sous le lieu qu'elle concerne.
class _IssueLine extends StatelessWidget {
  const _IssueLine({required this.issue});

  final ContentIssue issue;

  @override
  Widget build(BuildContext context) {
    final wrong = issue.severity == IssueSeverity.wrong;
    final color = wrong
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            wrong ? Icons.error_outline : Icons.pending_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              issue.message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le reperage d'un point : « A », « B1 », « C2 ».
class _Letter extends StatelessWidget {
  const _Letter(this.letter, {this.small = false});

  final String letter;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        letter,
        style: (small
                ? Theme.of(context).textTheme.labelSmall
                : Theme.of(context).textTheme.labelLarge)
            ?.copyWith(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
