import 'package:flutter/material.dart';
import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/application/adventure_outline.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/domain/repositories/picture_library.dart';
import 'package:grisbie/domain/models/adventure_opening.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/ui/pages/add_trips_page.dart';
import 'package:grisbie/ui/pages/adventure_opening_editor_page.dart';
import 'package:grisbie/ui/pages/stage_editor_page.dart';

/// Construire le parcours d'une aventure, point par point.
///
/// Reprend la forme du croquis papier de l'auteur : un point porte une lettre,
/// les trajets qui en partent se lisent en dessous, et **chaque arrivee devient
/// a son tour une carte plus bas**, prete a etre prolongee. Un lieu qu'on vient
/// de creer n'a pas encore de trajet : il a quand meme sa carte, sans quoi il
/// serait invisible et impossible a prolonger.
///
/// L'aventure ne quitte pas la memoire : cette page la modifie et la rend a
/// l'appelant. L'enregistrement est un autre sujet, et un autre ecran.
class OutlinePage extends StatefulWidget {
  const OutlinePage({
    required this.adventure,
    this.pictures,
    this.contentSource,
    this.onSave,
    super.key,
  });

  final Adventure adventure;

  /// Ce qui ecrit l'aventure, et rend les chemins touches.
  ///
  /// Nul, le bouton ne parait pas : une plateforme sans ou ecrire — ou un
  /// test — n'a pas a proposer un geste qui ne ferait rien. C'est le point
  /// d'entree qui sait ou l'on ecrit, pas cet ecran.
  final Future<List<String>> Function(Adventure adventure)? onSave;

  /// De quoi choisir une illustration dans l'appareil, transmise aux editeurs.
  final PictureLibrary? pictures;

  /// D'ou lire le contenu, illustrations comprises.
  ///
  /// Nulle, le bundle : c'est le cas du jeu et des tests. L'outil d'auteur y
  /// passe la source ou il travaille, pour que l'apercu montre l'image qu'il
  /// vient de deposer et non celle d'avant.
  final ContentSource? contentSource;


  @override
  State<OutlinePage> createState() => _OutlinePageState();
}

/// Ce que l'auteur choisit en quittant avec du travail non enregistre.
enum _Leaving {
  /// Rester sur le parcours : la sortie etait une erreur de geste.
  stay,

  /// Sortir en renoncant au travail — un geste legitime, mais voulu.
  discard,

  /// Ecrire, puis sortir.
  saveThenLeave,
}

class _OutlinePageState extends State<OutlinePage> {
  late Adventure _adventure = widget.adventure;

  /// Vrai des que l'aventure a l'ecran differe de la derniere version ecrite.
  ///
  /// **Le piege que cela repare** : « Garder » ferme un editeur et rend son
  /// resultat ici, en memoire ; seul « Enregistrer » ecrit. Quitter le
  /// parcours jetait donc tout le travail sans un mot, et l'auteur cherchait
  /// ensuite son aventure dans la liste de l'accueil.
  bool _unsaved = false;

  /// Vrai pendant l'ecriture : le bouton s'eteint, faute de quoi deux
  /// enregistrements concurrents se marcheraient dessus.
  bool _saving = false;

  /// Applique une modification et retient qu'elle n'est pas ecrite.
  ///
  /// Tous les changements passent par la : un `setState` direct oublierait le
  /// marqueur, et le silence reviendrait par la porte de derriere.
  void _change(Adventure next) {
    setState(() {
      _adventure = next;
      _unsaved = true;
    });
  }

  /// Demande les trajets a ajouter depuis ce lieu.
  ///
  /// [singleExit] vaut pour un tri unique : une seule sortie, celle du theme.
  Future<List<NewTrip>?> _askTrips(
    OutlineBlock block, {
    required bool singleExit,
  }) async {
    final trips = await Navigator.of(context).push<List<NewTrip>>(
      MaterialPageRoute<List<NewTrip>>(
        builder: (_) => AddTripsPage(
          locationName: block.locationName,
          allowsOneTripOnly: singleExit,
          existingTrips: block.trips
              .where((trip) => trip.destinationStageId != null)
              .map((trip) => trip.label)
              .toList(growable: false),
          // Le repertoire des fins : plusieurs chemins peuvent aboutir a la
          // meme, avec un seul ecran, une seule image et un seul texte.
          existingEndings: <String, String>{
            for (final ending in _adventure.endings)
              ending.id: ending.locationName,
          },
        ),
      ),
    );
    if (trips == null || trips.isEmpty) return null;
    return trips;
  }

  /// Ajoute des listes, et les trajets qu'elles ouvrent.
  ///
  /// Sert a definir un lieu a plusieurs listes comme a en ajouter ensuite —
  /// et a poser la sortie d'un tri unique qui n'en aurait pas.
  Future<void> _addTrips(OutlineBlock block) async {
    final trips = await _askTrips(block, singleExit: block.isSingleSort);
    if (trips == null) return;

    _change(AdventureBuilder(_adventure).addTrips(block.stageId, trips));
  }

  /// Fait du lieu un tri unique : le theme, sa sortie, et le reste.
  Future<void> _defineSingleSort(OutlineBlock block) async {
    final trips = await _askTrips(block, singleExit: true);
    if (trips == null) return;

    _change(
      AdventureBuilder(_adventure).defineAsSingleSort(block.stageId, trips.first),
    );
  }

  /// Fait du lieu une fin : du texte, pas de jeu.
  ///
  /// Aucune page a remplir : il n'y a rien a nommer. L'illustration et le
  /// texte d'arrivee se posent ensuite en ouvrant le lieu.
  void _defineEnding(OutlineBlock block) {
    _change(AdventureBuilder(_adventure).defineAsEnding(block.stageId));
  }

  /// Ouvre ce que le lieu porte : nom, illustration, zones, recits.
  ///
  /// Les mots n'y sont pas — ils appartiennent au trajet, et une meme liste
  /// sert a plusieurs lieux.
  Future<void> _editStage(OutlineBlock block) async {
    final stage = _adventure.findStage(block.stageId);
    if (stage == null) return;

    final edited = await Navigator.of(context).push<Stage>(
      MaterialPageRoute<Stage>(
        builder: (_) => StageEditorPage(
          stage: stage,
          pictures: widget.pictures,
          contentSource: widget.contentSource,
        ),
      ),
    );
    if (edited == null) return;

    _change(_adventure.withStage(edited));
  }

  /// Ouvre le seuil de l'aventure, qu'il existe deja ou non.
  Future<void> _editOpening() async {
    final edit = await Navigator.of(context).push<OpeningEdit>(
      MaterialPageRoute<OpeningEdit>(
        builder: (_) => AdventureOpeningEditorPage(
          adventureTitle: _adventure.title,
          opening: _adventure.opening,
          pictures: widget.pictures,
          contentSource: widget.contentSource,
        ),
      ),
    );
    if (edit == null) return;

    _change(_adventure.withOpening(edit.opening));
  }

  /// Ecrit l'aventure telle qu'elle est a cet instant.
  ///
  /// **C'est `_adventure` qui part, pas celle recue** : l'ecran travaille en
  /// memoire, et enregistrer l'aventure d'origine perdrait tout le travail.
  ///
  /// Rend vrai si l'ecriture a reussi — ce que « Enregistrer et quitter » doit
  /// savoir : sortir apres un echec perdrait le travail en croyant l'avoir mis
  /// a l'abri.
  Future<bool> _save() async {
    final onSave = widget.onSave;
    if (onSave == null) return false;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final written = await onSave(_adventure);
      if (mounted) setState(() => _unsaved = false);
      messenger.showSnackBar(
        SnackBar(content: Text('${written.length} fichier(s) enregistré(s).')),
      );
      return true;
    } catch (error) {
      // Un echec silencieux laisserait croire le contenu ecrit, et l'auteur
      // ne le decouvrirait qu'en le cherchant.
      messenger.showSnackBar(
        SnackBar(content: Text('Échec de l\'enregistrement : $error')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Demande quoi faire du travail non ecrit, au moment de sortir.
  ///
  /// Renoncer reste possible — c'est un geste legitime — mais il doit etre
  /// **voulu**. Sans cette question, quitter le parcours jetait tout en
  /// silence, et l'auteur cherchait ensuite son aventure dans la liste.
  Future<void> _leave() async {
    final canSave = widget.onSave != null;

    final choice = await showDialog<_Leaving>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non enregistrées'),
        content: Text(
          canSave
              ? 'Ce que vous venez d\'écrire n\'est encore qu\'à l\'écran. '
                  'Quitter maintenant le perdra.'
              : 'Ce que vous venez d\'écrire n\'est encore qu\'à l\'écran, et '
                  'il n\'y a nulle part où l\'enregistrer : aucun dépôt n\'est '
                  'configuré. Quitter maintenant le perdra.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(_Leaving.stay),
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_Leaving.discard),
            child: const Text('Quitter sans enregistrer'),
          ),
          // Pas de bouton d'ecriture sans destination : il ne ferait rien, et
          // au pire moment.
          if (canSave)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_Leaving.saveThenLeave),
              child: const Text('Enregistrer et quitter'),
            ),
        ],
      ),
    );

    if (!mounted || choice == null || choice == _Leaving.stay) return;

    if (choice == _Leaving.saveThenLeave && !await _save()) {
      // L'ecriture a echoue : rester est la seule issue qui ne perde rien.
      // Le message d'echec est deja affiche.
      return;
    }

    if (mounted) Navigator.of(context).pop(_adventure);
  }

  @override
  Widget build(BuildContext context) {
    final outline = AdventureOutline.of(_adventure);
    final issues = _adventure.validate();
    final detached = outline.detachedStageIds.toSet();

    // `PopScope` plutot qu'un simple bouton : le geste de retour du systeme
    // — celui d'Android, le glissement, la touche du navigateur — passe par
    // la aussi. Le proteger d'un seul cote ne protegerait rien.
    return PopScope<Adventure>(
      canPop: !_unsaved,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leave();
      },
      child: _buildScaffold(context, outline, issues, detached),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AdventureOutline outline,
    List<ContentIssue> issues,
    Set<String> detached,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_adventure.title),
        // Rendre l'aventure modifiee a l'appelant : rien ne la relit ailleurs.
        // `maybePop` pour que la question ci-dessus s'applique aussi ici.
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(_adventure),
        ),
        actions: <Widget>[
          if (widget.onSave != null)
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('Enregistrer'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: <Widget>[
          _IssueSummary(issues: issues),
          // Le seuil de la journee, avant le premier lieu — comme a l'ecran
          // du jeu. Il n'a pas de trajet : on n'en repart pas, on y entre.
          _OpeningCard(
            opening: _adventure.opening,
            onTap: _editOpening,
          ),
          for (final block in outline.blocks)
            _BlockCard(
              block: block,
              isDetached: detached.contains(block.stageId),
              issues: issues.where((i) => i.stageId == block.stageId).toList(),
              onAddTrips: () => _addTrips(block),
              onDefineSingleSort: () => _defineSingleSort(block),
              onDefineEnding: () => _defineEnding(block),
              onOpen: () => _editStage(block),
            ),
        ],
      ),
    );
  }
}

/// Ou en est l'aventure, en tete d'ecran : jouable, pas complete, ou fausse.
///
/// Trois etats et non deux : « jouable » est reserve a ce que le jeu ouvrira
/// vraiment, et un travail en cours n'est pas une faute. L'annoncer comme
/// telle apprendrait a ignorer l'ecran. L'etat vient du domaine
/// ([ContentReadiness]) ; cet ecran ne fait que le dire.
class _IssueSummary extends StatelessWidget {
  const _IssueSummary({required this.issues});

  final List<ContentIssue> issues;

  @override
  Widget build(BuildContext context) {
    final wrong =
        issues.where((i) => i.severity == IssueSeverity.wrong).length;
    final incomplete = issues.length - wrong;
    final errorColor = Theme.of(context).colorScheme.error;

    final (IconData icon, Color? color, String title, String? detail) =
        switch (ContentReadiness.of(issues)) {
      ContentReadiness.playable => (
          Icons.check_circle_outline,
          Colors.green.shade700,
          'Cette aventure est jouable.',
          null,
        ),
      ContentReadiness.incomplete => (
          Icons.pending_outlined,
          null,
          'Cette aventure n\'est pas complète.',
          '$incomplete à finir.',
        ),
      ContentReadiness.wrong => (
          Icons.error_outline,
          errorColor,
          'Cette aventure contient des erreurs.',
          incomplete > 0
              ? '$wrong à corriger, $incomplete à finir.'
              : '$wrong à corriger.',
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: color),
                ),
                if (detail != null)
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Le seuil de l'aventure, pose au-dessus du premier lieu.
///
/// Une carte plus discrete que celles des lieux, et sans lettre : ce n'est pas
/// un point du parcours, rien n'en part. Elle existe meme quand il n'y a pas
/// de page de garde — sans quoi il n'y aurait aucun endroit ou en creer une.
class _OpeningCard extends StatelessWidget {
  const _OpeningCard({required this.opening, required this.onTap});

  final AdventureOpening? opening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final opening = this.opening;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              const Icon(Icons.auto_stories_outlined, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Page de garde',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    if (opening == null)
                      _Note('Aucune. L\'aventure commence au premier lieu.')
                    else ...<Widget>[
                      if (opening.title != null) _Note(opening.title!),
                      if (opening.imageAsset == null)
                        _Note('Pas encore d\'illustration.'),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un point du parcours, avec les trajets qui en partent.
class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.block,
    required this.isDetached,
    required this.issues,
    required this.onAddTrips,
    required this.onDefineSingleSort,
    required this.onDefineEnding,
    required this.onOpen,
  });

  final OutlineBlock block;

  /// Vrai si aucun chemin ne mene ici : l'enfant ne le verra jamais.
  final bool isDetached;

  final List<ContentIssue> issues;

  /// Ajoute des listes et leurs trajets — ce qui fait aussi d'un lieu a
  /// definir un lieu a plusieurs listes.
  final VoidCallback onAddTrips;
  final VoidCallback onDefineSingleSort;
  final VoidCallback onDefineEnding;

  /// Ouvre ce que le lieu porte : nom, illustration, zones, recits.
  final VoidCallback onOpen;

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
                  child: InkWell(
                    onTap: onOpen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        block.locationName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
                if (block.isEncounter)
                  const Icon(Icons.person_outline, size: 18),
                if (block.isSingleSort)
                  const Icon(Icons.filter_alt_outlined, size: 18),
                if (block.isEnding) const Icon(Icons.flag_outlined, size: 18),
                // La case du croquis : le recit d'arrivee est-il ecrit ?
                Icon(
                  block.hasNarrative
                      ? Icons.check_box_outlined
                      : Icons.check_box_outline_blank,
                  size: 18,
                ),
              ],
            ),
            if (isDetached) _Note('Aucun chemin ne mène ici.'),
            if (block.isEnding)
              _Note('Fin de l\'aventure : du texte, pas de jeu.'),
            if (block.nature == StageNature.sorting)
              _Note('Plusieurs listes : l\'enfant range dans chacune.'),
            if (block.isSingleSort)
              _Note('Tri unique : ce qui est du thème, et tout le reste.'),
            const SizedBox(height: 8),
            for (final trip in block.trips) _buildTrip(context, trip),
            for (final issue in issues) _IssueLine(issue: issue),
            ..._buildActions(context),
          ],
        ),
      ),
    );
  }

  /// Ce que la carte propose, selon ce que l'enfant fait ici.
  ///
  /// **Un lieu a definir pose la question**, et c'est la seule chose qu'il
  /// propose : la nature decide de tout le reste. Une fin ne propose rien —
  /// la journee s'y arrete, et proposer d'en repartir contredirait ce que la
  /// carte vient d'annoncer. Un tri unique n'a qu'une sortie : une fois posee,
  /// il n'y a plus rien a ajouter.
  List<Widget> _buildActions(BuildContext context) {
    switch (block.nature) {
      case StageNature.undefined:
        return <Widget>[
          const SizedBox(height: 4),
          Text(
            'Que fait l\'enfant ici ?',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onAddTrips,
                icon: const Icon(Icons.dashboard_outlined, size: 18),
                label: const Text('Plusieurs listes'),
              ),
              OutlinedButton.icon(
                onPressed: onDefineSingleSort,
                icon: const Icon(Icons.filter_alt_outlined, size: 18),
                label: const Text('Tri unique'),
              ),
              OutlinedButton.icon(
                onPressed: onDefineEnding,
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Une fin'),
              ),
            ],
          ),
        ];

      case StageNature.sorting:
        return <Widget>[_actionButton('Ajouter')];

      case StageNature.singleSort:
        // Un tri unique ecrit a la main peut n'avoir que sa liste du reste.
        final hasExit =
            block.trips.any((trip) => trip.destinationStageId != null);
        return hasExit
            ? const <Widget>[]
            : <Widget>[_actionButton('Ajouter la sortie')];

      case StageNature.ending:
        return const <Widget>[];
    }
  }

  Widget _actionButton(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: onAddTrips,
          icon: const Icon(Icons.add),
          label: Text(label),
        ),
      ),
    );
  }

  Widget _buildTrip(BuildContext context, OutlineTrip trip) {
    return Padding(
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
          Expanded(child: _tripText(context, trip)),
          if (trip.leadsToSingleSort)
            const Icon(Icons.filter_alt_outlined, size: 16),
          if (trip.leadsToEnding) const Icon(Icons.flag_outlined, size: 16),
          // La liste du reste n'ouvre aucun chemin, et c'est sa raison d'etre :
          // l'annoncer « sans issue » la ferait passer pour un defaut.
          if (trip.destinationStageId == null)
            Text('le reste', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  /// Le trajet, et le lieu ou il mene : « En bus → La gare ».
  ///
  /// La lettre du lieu suffisait a faire le lien, mais obligeait a descendre
  /// chercher sa carte pour savoir de quel lieu il s'agit. Sur le croquis
  /// papier de l'auteur, la fleche portait les deux bouts.
  ///
  /// Un seul texte enrichi plutot que deux widgets cote a cote : il se replie
  /// tout seul sur un telephone etroit, la ou deux `Text` se disputeraient la
  /// largeur.
  Widget _tripText(BuildContext context, OutlineTrip trip) {
    final destination = trip.destinationName;

    // « En bus → En bus » serait du bruit, et se lirait comme un defaut. C'est
    // le cas de tout ce qui a ete cree avant que les deux noms se distinguent,
    // et de tout trajet dont l'auteur laisse le lieu porter le meme nom.
    if (destination == null || destination == trip.label) {
      return Text(trip.label);
    }

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: trip.label),
          TextSpan(
            text: ' → $destination',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Une precision discrete sous le titre d'un point.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 8),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
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
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
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
