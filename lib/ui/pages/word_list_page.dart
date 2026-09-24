import 'package:flutter/material.dart';
import 'package:grisbie/application/word_list_builder.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/models/word_library.dart';
import 'package:grisbie/domain/models/word_list.dart';
import 'package:grisbie/ui/widgets/supply_summary.dart';

/// La liste de mots d'un trajet, ouverte en le touchant sur sa carte.
///
/// **Il n'y a pas de mot seul.** Un trajet sans liste en recoit une — neuve,
/// ou reprise d'une liste existante —, et les mots n'entrent que par elle. Un
/// mot n'est que son orthographe : on le tape, et il entre.
///
/// Le **reste d'un tri unique** ne s'ecrit pas mot a mot : l'auteur y coche
/// les listes ou le jeu peut prendre les mots qui ne sont pas du theme.
///
/// La page ne decide rien : elle passe les gestes a [WordListBuilder] et
/// reaffiche l'aventure qu'il rend. Comme les autres editeurs, elle travaille
/// en memoire et dit « Garder » : c'est « Enregistrer », sur le parcours, qui
/// ecrit.
class WordListPage extends StatefulWidget {
  const WordListPage({
    required this.adventure,
    required this.stageId,
    required this.familyId,
    this.library = WordLibrary.empty,
    super.key,
  });

  final Adventure adventure;
  final String stageId;
  final String familyId;

  /// Le vocabulaire deja ecrit : listes a reutiliser, decoupages connus.
  final WordLibrary library;

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  late Adventure _adventure = widget.adventure;

  final TextEditingController _wordText = TextEditingController();

  /// Le champ du mot, rendu a l'auteur apres chaque ajout.
  final FocusNode _wordFocus = FocusNode();

  WordListBuilder get _builder =>
      WordListBuilder(_adventure, library: widget.library);

  Stage get _stage => _adventure.findStage(widget.stageId)!;

  WordFamily get _family => _stage.findFamily(widget.familyId)!;

  @override
  void dispose() {
    _wordText.dispose();
    _wordFocus.dispose();
    super.dispose();
  }

  /// Applique un geste ; un refus du moteur se dit, il ne casse rien.
  bool _apply(Adventure Function(WordListBuilder builder) change) {
    try {
      final next = change(_builder);
      setState(() => _adventure = next);
      return true;
    } on StateError catch (error) {
      _tell(error.message);
    } on ArgumentError catch (error) {
      _tell('${error.message}');
    }
    return false;
  }

  void _tell(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final family = _family;

    return Scaffold(
      appBar: AppBar(
        title: Text(family.label),
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
            'Dans « ${_stage.locationName} »',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          if (!family.leadsSomewhere)
            ..._buildPool(context, family)
          else if (family.lists.isEmpty)
            ..._buildNoList(context)
          else
            ..._buildList(context, family),
        ],
      ),
    );
  }

  // --- Un trajet sans liste ------------------------------------------------

  List<Widget> _buildNoList(BuildContext context) {
    return <Widget>[
      const Text('Ce trajet n\'a pas encore de liste de mots.'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          FilledButton.icon(
            onPressed: _createList,
            icon: const Icon(Icons.add),
            label: const Text('Créer une liste'),
          ),
          OutlinedButton.icon(
            onPressed: _reuseList,
            icon: const Icon(Icons.library_books_outlined),
            label: const Text('Réutiliser une liste'),
          ),
        ],
      ),
    ];
  }

  Future<void> _createList() async {
    final name = await _askText(
      title: 'Nouvelle liste',
      label: 'Son nom',
      helper: 'Pour vous la retrouver. L\'enfant lit le nom du trajet.',
      initial: _family.label,
    );
    if (name == null || name.trim().isEmpty) return;

    _apply(
      (builder) =>
          builder.createListFor(widget.stageId, widget.familyId, name: name),
    );
  }

  Future<void> _reuseList() async {
    final current = _family.lists.map((list) => list.id).toSet();
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Réutiliser une liste'),
        children: <Widget>[
          for (final list in _builder.knownLists)
            if (!current.contains(list.id))
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(list.id),
                child: _ListChoice(list: list),
              ),
        ],
      ),
    );
    if (chosen == null) return;

    _apply(
      (builder) => builder.useListFor(widget.stageId, widget.familyId, chosen),
    );
  }

  // --- Un trajet et sa liste -----------------------------------------------

  List<Widget> _buildList(BuildContext context, WordFamily family) {
    final list = family.list;
    final elsewhere = _builder
        .usagesOf(list.id)
        .where(
          (usage) =>
              usage.stageId != widget.stageId ||
              usage.familyId != widget.familyId,
        )
        .toList(growable: false);
    final shared = _stage.sharedWordTextsIn(family);

    return <Widget>[
      Row(
        children: <Widget>[
          const Icon(Icons.list_alt, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              list.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Renommer la liste',
            onPressed: () => _renameList(list),
          ),
          PopupMenuButton<String>(
            tooltip: 'Changer de liste',
            onSelected: (choice) =>
                choice == 'new' ? _createList() : _reuseList(),
            itemBuilder: (context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'new',
                child: Text('Créer une autre liste'),
              ),
              PopupMenuItem<String>(
                value: 'reuse',
                child: Text('Réutiliser une autre liste'),
              ),
            ],
          ),
        ],
      ),
      // Une liste est la meme partout ou elle sert : la modifier ici la
      // modifie la-bas. Le dire **avant** qu'on y touche.
      if (elsewhere.isNotEmpty)
        _Notice(
          icon: Icons.share_outlined,
          text:
              'Cette liste sert aussi à : '
              '${elsewhere.map((u) => '${u.locationName} — ${u.familyLabel}').join(', ')}. '
              'La modifier ici la modifie là aussi.',
        ),
      const SizedBox(height: 8),
      SupplySummary(supply: _stage.supplyOf(family)),
      for (final issue in _issuesOf(family)) _IssueNotice(issue: issue),
      const SizedBox(height: 16),
      _buildWordForm(context, list),
      const SizedBox(height: 16),
      if (list.isEmpty)
        const Text('Aucun mot pour l\'instant.')
      else
        // Dans l'ordre alphabetique, quel que soit celui du fichier : une
        // liste se relit dans l'ordre ou l'on y chercherait un mot.
        for (final word in <Word>[...list.words]
          ..sort(Word.compareAlphabetically))
          _WordTile(
            word: word,
            isShared: shared.contains(word.text),
            onRemove: () =>
                _apply((builder) => builder.removeWord(list.id, word.text)),
          ),
    ];
  }

  /// Les anomalies de cette famille, a voir la ou l'on ecrit ses mots.
  List<ContentIssue> _issuesOf(WordFamily family) {
    return _adventure
        .validate()
        .where(
          (issue) =>
              issue.stageId == widget.stageId &&
              issue.familyId == widget.familyId,
        )
        .toList(growable: false);
  }

  bool get _canAddWord => _wordText.text.trim().isNotEmpty;

  Widget _buildWordForm(BuildContext context, WordList list) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: TextField(
            key: const Key('word-text'),
            controller: _wordText,
            focusNode: _wordFocus,
            decoration: const InputDecoration(
              labelText: 'Un mot',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
            // Au clavier d'un poste, on enchaine les mots sans lacher les
            // touches : Entree ajoute, et le champ reste pret pour le suivant.
            onSubmitted: (_) {
              if (_canAddWord) _addWord(list);
            },
            // Sans ce rappel, Entree rendrait la main au reste de l'ecran,
            // meme sur un champ vide.
            onEditingComplete: () {},
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: FilledButton.icon(
            key: const Key('word-add'),
            onPressed: _canAddWord ? () => _addWord(list) : null,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
        ),
      ],
    );
  }

  void _addWord(WordList list) {
    final added = _apply(
      (builder) => builder.addWord(list.id, text: _wordText.text),
    );
    if (!added) return;

    // On enchaine les mots : le champ se vide pour le suivant, et le curseur
    // y revient — apres le bouton comme apres Entree, sans reprendre la
    // souris.
    _wordText.clear();
    _wordFocus.requestFocus();
    setState(() {});
  }

  Future<void> _renameList(WordList list) async {
    final name = await _askText(
      title: 'Renommer la liste',
      label: 'Son nom',
      initial: list.name,
    );
    if (name == null || name.trim().isEmpty) return;

    _apply((builder) => builder.renameList(list.id, name));
  }

  // --- Le reste d'un tri unique --------------------------------------------

  List<Widget> _buildPool(BuildContext context, WordFamily family) {
    final checked = family.lists.map((list) => list.id).toList();
    // Le theme ne se coche pas : ses mots sont precisement ceux que le reste
    // exclut.
    final theme = <String>{
      for (final other in _stage.families)
        if (other.leadsSomewhere)
          for (final list in other.lists) list.id,
    };

    return <Widget>[
      const Text(
        'Le jeu tire ici des mots qui ne sont pas du thème, dans les listes '
        'que vous cochez.',
      ),
      const SizedBox(height: 4),
      Text(
        'Ne cochez que des listes sûres pour ce thème : un mot du thème absent '
        'de sa liste serait refusé à l\'enfant qui le range à juste titre.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      SupplySummary(supply: _stage.supplyOf(family)),
      for (final issue in _issuesOf(family)) _IssueNotice(issue: issue),
      const SizedBox(height: 8),
      for (final list in _builder.knownLists)
        if (!theme.contains(list.id))
          CheckboxListTile(
            value: checked.contains(list.id),
            contentPadding: EdgeInsets.zero,
            title: Text(list.name),
            subtitle: Text(_preview(list)),
            onChanged: (value) {
              final next = List<String>.of(checked);
              if (value == true) {
                next.add(list.id);
              } else {
                next.remove(list.id);
              }
              _apply(
                (builder) => builder.setPooledLists(
                  widget.stageId,
                  widget.familyId,
                  next,
                ),
              );
            },
          ),
    ];
  }

  // --- Commun ----------------------------------------------------------------

  Future<String?> _askText({
    required String title,
    required String label,
    String? helper,
    String initial = '',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => _TextDialog(
        title: title,
        label: label,
        helper: helper,
        initial: initial,
      ),
    );
  }
}

/// Une question a une ligne de reponse.
///
/// Un widget a etat, et non un controleur cree par l'appelant : la boite
/// continue de s'afficher pendant qu'elle se referme, et un controleur libere
/// des le retour de `showDialog` etait encore lu par l'animation.
class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    required this.initial,
    this.helper,
  });

  final String title;
  final String label;
  final String? helper;
  final String initial;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
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
      title: Text(widget.title),
      content: TextField(
        key: const Key('dialog-text'),
        controller: _text,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: widget.helper,
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

/// Les premiers mots d'une liste, pour la reconnaitre avant de la choisir.
String _preview(WordList list) {
  if (list.isEmpty) return 'Vide';
  final shown = list.words.take(5).map((word) => word.text).join(', ');
  final more = list.length > 5 ? '…' : '';
  return '${list.length} mots : $shown$more';
}

class _ListChoice extends StatelessWidget {
  const _ListChoice({required this.list});

  final WordList list;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(list.name),
        Text(_preview(list), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Un mot de la liste, et ce qu'il devient ici.
class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.word,
    required this.isShared,
    required this.onRemove,
  });

  final Word word;

  /// Vrai si le mot est aussi dans une liste voisine : il ne jouera pas ici.
  final bool isShared;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(word.text),
      subtitle: isShared
          ? const Text('Commun à une autre liste du lieu : retiré ici')
          : null,
      leading: Icon(
        isShared ? Icons.call_split : Icons.label_outline,
        size: 20,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        tooltip: 'Retirer « ${word.text} »',
        onPressed: onRemove,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _IssueNotice extends StatelessWidget {
  const _IssueNotice({required this.issue});

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
      IssueSeverity.incomplete => (Icons.pending_outlined, null),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
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
