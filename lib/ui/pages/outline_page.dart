import 'package:flutter/material.dart';
import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/application/adventure_outline.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/domain/repositories/picture_catalog.dart';
import 'package:grisbie/domain/models/adventure_opening.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/word_library.dart';
import 'package:grisbie/infrastructure/content/content_integrator.dart';
import 'package:grisbie/infrastructure/content/preloaded_adventure_repository.dart';
import 'package:grisbie/ui/pages/add_trips_page.dart';
import 'package:grisbie/ui/pages/adventure_opening_editor_page.dart';
import 'package:grisbie/ui/pages/adventure_page.dart';
import 'package:grisbie/ui/pages/cover_editor_page.dart';
import 'package:grisbie/ui/pages/stage_appearance_page.dart';
import 'package:grisbie/ui/pages/stage_texts_page.dart';
import 'package:grisbie/ui/pages/stage_page.dart';
import 'package:grisbie/ui/pages/stage_structure_page.dart';
import 'package:grisbie/ui/pages/word_list_page.dart';
import 'package:grisbie/ui/widgets/supply_summary.dart';

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
    this.onIntegrate,
    this.library = WordLibrary.empty,
    super.key,
  });

  final Adventure adventure;

  /// Le vocabulaire deja ecrit, pour reutiliser une liste et retrouver le
  /// decoupage d'un mot. Vide, on ne peut que creer.
  final WordLibrary library;

  /// Ce qui ecrit l'aventure, et rend les chemins touches.
  ///
  /// Nul, le bouton ne parait pas : une plateforme sans ou ecrire — ou un
  /// test — n'a pas a proposer un geste qui ne ferait rien. C'est le point
  /// d'entree qui sait ou l'on ecrit, pas cet ecran.
  final Future<List<String>> Function(Adventure adventure)? onSave;

  /// Verse l'aventure dans le dossier du contenu du depot git, et rend les
  /// chemins ecrits — ou `null` si l'auteur renonce a designer le dossier.
  /// Refuse par `IntegrationRefused`, en nommant chaque raison.
  ///
  /// Nul la ou l'on ne peut pas designer de dossier (hors de Chrome) : le
  /// bouton ne parait pas.
  final Future<List<String>?> Function(Adventure adventure)? onIntegrate;

  /// Les images du depot, transmises aux editeurs.
  final PictureCatalog? pictures;

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
          // Tout lieu deja ecrit peut etre rejoint — une fin partagee, le plus
          // souvent. Revenir en arriere est permis : la boucle est signalee,
          // a verifier. Le lieu d'ou l'on part n'est pas propose.
          existingPlaces: <String, String>{
            for (final stage in _adventure.stages.values)
              if (stage.id != block.stageId) stage.id: stage.locationName,
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
      AdventureBuilder(
        _adventure,
      ).defineAsSingleSort(block.stageId, trips.first),
    );
  }

  /// Fait du lieu une fin : du texte, pas de jeu.
  ///
  /// Aucune page a remplir : il n'y a rien a nommer. L'illustration et le
  /// texte d'arrivee se posent ensuite en ouvrant le lieu.
  void _defineEnding(OutlineBlock block) {
    _change(AdventureBuilder(_adventure).defineAsEnding(block.stageId));
  }

  /// Ouvre la structure du lieu : sa nature et ses trajets.
  ///
  /// Le troisieme geste de la carte : le titre ouvre ce que le lieu montre,
  /// un trajet ouvre sa liste, la ligne de nature ouvre le circuit.
  Future<void> _editStructure(OutlineBlock block) async {
    final edited = await Navigator.of(context).push<Adventure>(
      MaterialPageRoute<Adventure>(
        builder: (_) => StageStructurePage(
          adventure: _adventure,
          stageId: block.stageId,
        ),
      ),
    );
    if (edited == null) return;

    _change(edited);
  }

  /// Supprime un lieu que plus rien n'atteint, apres confirmation.
  ///
  /// Le seul endroit ou un lieu disparait : retirer ou rediriger un trajet le
  /// laisse, detache, pour que rien ne se perde sans avoir ete voulu.
  Future<void> _removeStage(OutlineBlock block) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer « ${block.locationName} »'),
        content: const Text(
          'Ce lieu, son illustration, ses récits et ses trajets seront '
          'retirés de l\'aventure. Les lieux où ses trajets menaient restent.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _change(AdventureBuilder(_adventure).removeStage(block.stageId));
  }

  /// Ouvre la liste de mots d'un trajet — ou, pour le reste d'un tri unique,
  /// les listes ou il puise.
  ///
  /// Les listes appartiennent au trajet et non au lieu : c'est pourquoi on y
  /// arrive en touchant le trajet.
  Future<void> _openList(OutlineBlock block, OutlineTrip trip) async {
    final edited = await Navigator.of(context).push<Adventure>(
      MaterialPageRoute<Adventure>(
        builder: (_) => WordListPage(
          adventure: _adventure,
          stageId: block.stageId,
          familyId: trip.familyId,
          library: widget.library,
        ),
      ),
    );
    if (edited == null) return;

    _change(edited);
  }

  /// Ouvre ce que le lieu porte : nom, illustration, zones, recits.
  ///
  /// Les mots n'y sont pas — ils appartiennent au trajet, et une meme liste
  /// sert a plusieurs lieux.
  /// Joue ce lieu seul, avec le vrai ecran de jeu, jusqu'au premier depart.
  ///
  /// Ce qui a ete regle sur l'ordinateur se verifie ainsi au doigt, sur
  /// l'ecran reel de l'appareil. Le lieu joue est celui **de l'ecran**,
  /// enregistre ou non : c'est ce qu'on vient de regler qu'on veut eprouver.
  /// Partir ramene au parcours — la suite n'est pas ce qu'on essaie.
  Future<void> _tryStage(OutlineBlock block) async {
    final stage = _adventure.findStage(block.stageId);
    if (stage == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (trialContext) => StagePage(
          stage: stage,
          contentSource: widget.contentSource,
          onDeparture: (_) => Navigator.of(trialContext).pop(),
        ),
      ),
    );
  }

  /// Joue l'aventure entiere, page de garde comprise, comme le jeu livre.
  ///
  /// Le meme ecran que le jeu (`AdventurePage`), nourri de l'aventure de
  /// l'ecran : le retour du systeme ramene au parcours.
  Future<void> _playAdventure() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdventurePage(
          repository: PreloadedAdventureRepository(_adventure),
          adventureId: _adventure.id,
        ),
      ),
    );
  }

  /// Ouvre l'apparence du lieu : son illustration et ses cadres.
  Future<void> _editAppearance(OutlineBlock block) async {
    await _editWith(
      block,
      (stage) => StageAppearancePage(
        stage: stage,
        pictures: widget.pictures,
        contentSource: widget.contentSource,
      ),
    );
  }

  /// Ouvre les textes du lieu, en diapositives.
  Future<void> _editTexts(OutlineBlock block) async {
    await _editWith(
      block,
      (stage) => StageTextsPage(
        stage: stage,
        contentSource: widget.contentSource,
      ),
    );
  }

  Future<void> _editWith(
    OutlineBlock block,
    Widget Function(Stage stage) editor,
  ) async {
    final stage = _adventure.findStage(block.stageId);
    if (stage == null) return;

    final edited = await Navigator.of(context).push<Stage>(
      MaterialPageRoute<Stage>(builder: (_) => editor(stage)),
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

  /// Ouvre la vignette de l'aventure, qu'elle existe deja ou non.
  Future<void> _editCover() async {
    final edit = await Navigator.of(context).push<CoverEdit>(
      MaterialPageRoute<CoverEdit>(
        builder: (_) => CoverEditorPage(
          coverAsset: _adventure.coverAsset,
          pictures: widget.pictures,
          contentSource: widget.contentSource,
        ),
      ),
    );
    if (edit == null) return;

    _change(_adventure.withCover(edit.coverAsset));
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

  /// Verse l'aventure de l'ecran dans le depot git, pour qu'elle soit jouable
  /// a la compilation suivante.
  ///
  /// Seule une aventure jouable s'integre : le jeu refuserait les autres. On
  /// dit d'abord ce qui va se passer — le dossier a designer, et ce qui
  /// restera a faire (commit, compilation) —, puis ce qui a ete ecrit, ou
  /// chaque raison du refus.
  Future<void> _integrate() async {
    final onIntegrate = widget.onIntegrate;
    if (onIntegrate == null) return;

    final messenger = ScaffoldMessenger.of(context);
    if (ContentReadiness.of(_adventure.validate()) !=
        ContentReadiness.playable) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Seule une aventure jouable s\'intègre au dépôt.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Intégrer au dépôt'),
        content: Text(
          'Désignez le dossier « assets/content » de votre copie du dépôt. '
          '« ${_adventure.title} » y sera écrite avec ses listes et ses mots ; '
          'ses images doivent déjà être dans « pictures ».\n\n'
          'Il restera à faire le commit, puis à recompiler le jeu.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Choisir le dossier'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    String title;
    String message;
    try {
      final written = await onIntegrate(_adventure);
      // Refermer le selecteur est un geste normal : rien a dire.
      if (written == null) return;
      title = 'Aventure intégrée';
      message = '${written.length} fichier(s) écrit(s) :\n'
          '${written.map((path) => '• $path').join('\n')}\n\n'
          'Reste à faire le commit, puis à recompiler le jeu.';
    } on IntegrationRefused catch (refusal) {
      title = 'Intégration refusée';
      message = 'Rien n\'a été écrit.\n\n'
          '${refusal.reasons.map((reason) => '• $reason').join('\n')}';
    } catch (error) {
      // Un refus du navigateur, un dossier en lecture seule : le taire
      // laisserait croire l'aventure versee.
      title = 'Échec de l\'intégration';
      message = '$error';
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
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
              onPressed: () =>
                  Navigator.of(context).pop(_Leaving.saveThenLeave),
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
          if (widget.onIntegrate != null)
            TextButton(
              onPressed: _integrate,
              child: const Text('Intégrer au dépôt'),
            ),
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
          _IssueSummary(issues: issues, onPlay: _playAdventure),
          // Ce qui represente l'aventure sur l'accueil du jeu, avant meme
          // qu'on y entre : d'ou sa place, en tete.
          _CoverCard(coverAsset: _adventure.coverAsset, onTap: _editCover),
          // Le seuil de la journee, avant le premier lieu — comme a l'ecran
          // du jeu. Il n'a pas de trajet : on n'en repart pas, on y entre.
          _OpeningCard(opening: _adventure.opening, onTap: _editOpening),
          for (final block in outline.blocks)
            _BlockCard(
              block: block,
              isDetached: detached.contains(block.stageId),
              // Les textes manquants se disent d'un seul compte, sur le
              // bouton « Textes » : une ligne chacun noyait la carte.
              issues: issues
                  .where((i) => i.stageId == block.stageId && !i.isMissingText)
                  .toList(),
              onAddTrips: () => _addTrips(block),
              onDefineSingleSort: () => _defineSingleSort(block),
              onDefineEnding: () => _defineEnding(block),
              onOpen: () => _editAppearance(block),
              onEditTexts: () => _editTexts(block),
              onOpenTrip: (trip) => _openList(block, trip),
              onEditStructure: () => _editStructure(block),
              onRemove: () => _removeStage(block),
              onTry: () => _tryStage(block),
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
  const _IssueSummary({required this.issues, required this.onPlay});

  final List<ContentIssue> issues;

  /// Joue l'aventure entiere — offert seulement quand elle est jouable : un
  /// essai qui s'arreterait sur un lieu inacheve ne dirait rien du jeu.
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    int count(IssueSeverity severity) =>
        issues.where((i) => i.severity == severity).length;
    final wrong = count(IssueSeverity.wrong);
    final incomplete = count(IssueSeverity.incomplete);
    final toCheck = count(IssueSeverity.warning);
    // Les boucles ne changent pas l'etat, mais se comptent : c'est ici qu'on
    // les voit toutes d'un coup.
    final checkNote = toCheck > 0 ? ' $toCheck à vérifier.' : '';
    final errorColor = Theme.of(context).colorScheme.error;

    final readiness = ContentReadiness.of(issues);
    final (
      IconData icon,
      Color? color,
      String title,
      String? detail,
    ) = switch (readiness) {
      ContentReadiness.playable => (
        Icons.check_circle_outline,
        Colors.green.shade700,
        'Cette aventure est jouable.',
        toCheck > 0 ? '$toCheck à vérifier.' : null,
      ),
      ContentReadiness.incomplete => (
        Icons.pending_outlined,
        null,
        'Cette aventure n\'est pas complète.',
        '$incomplete à finir.$checkNote',
      ),
      ContentReadiness.wrong => (
        Icons.error_outline,
        errorColor,
        'Cette aventure contient des erreurs.',
        '${incomplete > 0 ? '$wrong à corriger, $incomplete à finir.' : '$wrong à corriger.'}$checkNote',
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: color),
                ),
                if (detail != null)
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (readiness == ContentReadiness.playable)
            FilledButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Jouer l\'aventure'),
            ),
        ],
      ),
    );
  }
}

/// La vignette de l'aventure, en tete du parcours.
///
/// Discrete comme la carte de la page de garde, et pour la meme raison : ce
/// n'est pas un point du parcours. Elle existe sans vignette, sans quoi il
/// n'y aurait aucun endroit ou en poser une.
class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.coverAsset, required this.onTap});

  final String? coverAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coverAsset = this.coverAsset;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              const Icon(Icons.photo_outlined, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Vignette de l\'aventure',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    _Note(
                      coverAsset ??
                          'Aucune : l\'accueil du jeu n\'aurait rien à montrer.',
                    ),
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
    required this.onEditTexts,
    required this.onOpenTrip,
    required this.onEditStructure,
    required this.onRemove,
    required this.onTry,
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

  /// Ouvre l'apparence du lieu : illustration et cadres.
  final VoidCallback onOpen;

  /// Ouvre les textes du lieu, en diapositives.
  final VoidCallback onEditTexts;

  /// Ouvre la liste de mots d'un trajet.
  final void Function(OutlineTrip trip) onOpenTrip;

  /// Ouvre la structure du lieu : sa nature et ses trajets.
  final VoidCallback onEditStructure;

  /// Supprime le lieu — offert seulement quand rien n'y mene.
  final VoidCallback onRemove;

  /// Joue le lieu seul, sur l'appareil — offert quand il se joue seul.
  final VoidCallback onTry;

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
                if (block.isSingleSort)
                  const Icon(Icons.filter_alt_outlined, size: 18),
                if (block.isEnding) const Icon(Icons.flag_outlined, size: 18),
                // **La premiere ligne ne gere que l'apparence** (decision de
                // l'auteur) : l'image et la place des cadres.
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Apparence'),
                ),
              ],
            ),
            if (isDetached)
              Row(
                children: <Widget>[
                  Expanded(child: _Note('Aucun chemin ne mène ici.')),
                  // Le seul endroit ou un lieu disparait, et seulement quand
                  // plus rien n'y mene : aucun trajet ne mene alors nulle part.
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Supprimer ce lieu'),
                  ),
                ],
              ),
            // **La seconde ligne gere les textes**, avec « Ajouter » au meme
            // endroit : ajouter un trajet, c'est d'abord le nommer.
            _buildTextsLine(context),
            const SizedBox(height: 8),
            for (final trip in block.trips) _buildTrip(context, trip),
            for (final issue in issues) _IssueLine(issue: issue),
            if (block.canBeTried)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTry,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Essayer ce lieu'),
                ),
              ),
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
      case StageNature.singleSort:
      case StageNature.ending:
        return const <Widget>[];
    }
  }

  /// La nature du lieu, ses textes, et de quoi ajouter un trajet.
  Widget _buildTextsLine(BuildContext context) {
    final addLabel = _addLabel;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: <Widget>[
        if (block.nature != StageNature.undefined)
          _NatureLine(nature: block.nature, onTap: onEditStructure),
        _TextsButton(missing: block.missingTextCount, onTap: onEditTexts),
        if (addLabel != null)
          TextButton.icon(
            onPressed: onAddTrips,
            icon: const Icon(Icons.add, size: 18),
            label: Text(addLabel),
          ),
      ],
    );
  }

  /// Ce que « Ajouter » ajoute ici, ou `null` s'il n'y a rien a ajouter.
  ///
  /// Une fin ne propose rien — la journee s'y arrete. Un tri unique n'a
  /// qu'une sortie : une fois posee, il n'y a plus rien a ajouter.
  String? get _addLabel {
    switch (block.nature) {
      case StageNature.sorting:
        return 'Ajouter';
      case StageNature.singleSort:
        // Un tri unique ecrit a la main peut n'avoir que sa liste du reste.
        final hasExit = block.trips.any(
          (trip) => trip.destinationStageId != null,
        );
        return hasExit ? null : 'Ajouter la sortie';
      case StageNature.undefined:
      case StageNature.ending:
        return null;
    }
  }

  Widget _buildTrip(BuildContext context, OutlineTrip trip) {
    return InkWell(
      onTap: () => onOpenTrip(trip),
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
            Expanded(child: _tripText(context, trip)),
            if (trip.leadsToSingleSort)
              const Icon(Icons.filter_alt_outlined, size: 16),
            if (trip.leadsToEnding) const Icon(Icons.flag_outlined, size: 16),
            // La liste du reste n'ouvre aucun chemin, et c'est sa raison d'etre :
            // l'annoncer « sans issue » la ferait passer pour un defaut.
            if (trip.destinationStageId == null)
              Text('autre chose', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 8),
            // La question de la carte : une fois retires les mots communs, en
            // reste-t-il assez pour jouer ?
            if (trip.supply != null)
              SupplySummary(supply: trip.supply!, compact: true)
            else
              Text(
                'pas de liste',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
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

/// Ce que l'enfant fait ici, et le geste pour y revenir.
///
/// La ligne se touche : elle ouvre la structure du lieu. L'icone de reglage
/// le dit, sans quoi rien ne distinguerait cette ligne d'une simple note.
class _NatureLine extends StatelessWidget {
  const _NatureLine({required this.nature, required this.onTap});

  final StageNature nature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = switch (nature) {
      StageNature.ending => 'Fin de l\'aventure : du texte, pas de jeu.',
      StageNature.sorting => 'Plusieurs listes : l\'enfant range dans chacune.',
      StageNature.singleSort =>
        'Tri unique : ce qui est du thème, et tout le reste.',
      StageNature.undefined => '',
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(child: _Note(text)),
            const SizedBox(width: 4),
            Tooltip(
              message: 'Modifier la structure du lieu',
              child: Icon(
                Icons.tune,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le bouton des textes d'un lieu, qui dit combien restent a ecrire.
///
/// Le « Bravo ! » et l'action de depart de chaque trajet sont obligatoires :
/// en orange tant qu'il en manque, coche une fois tout ecrit.
class _TextsButton extends StatelessWidget {
  const _TextsButton({required this.missing, required this.onTap});

  final int missing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final complete = missing == 0;
    final color = complete
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFFB26A00);
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: color),
      icon: Icon(
        complete ? Icons.check_circle_outline : Icons.edit_note,
        size: 18,
      ),
      label: Text(
        complete
            ? 'Textes'
            : 'Textes · $missing à écrire',
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
    final (IconData icon, Color? color) = switch (issue.severity) {
      IssueSeverity.wrong => (
        Icons.error_outline,
        Theme.of(context).colorScheme.error,
      ),
      // A verifier : une boucle, permise mais a regarder.
      IssueSeverity.warning => (Icons.loop, Colors.orange.shade800),
      IssueSeverity.incomplete => (
        Icons.pending_outlined,
        Theme.of(context).textTheme.bodySmall?.color,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              issue.message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
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
        style:
            (small
                    ? Theme.of(context).textTheme.labelSmall
                    : Theme.of(context).textTheme.labelLarge)
                ?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
      ),
    );
  }
}
