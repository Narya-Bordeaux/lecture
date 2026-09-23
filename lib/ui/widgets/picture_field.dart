import 'package:flutter/material.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/domain/repositories/picture_catalog.dart';
import 'package:grisbie/ui/pages/picture_chooser_page.dart';
import 'package:grisbie/ui/widgets/content_image.dart';

/// Le champ d'une illustration : le chemin, le choix dans le depot, l'apercu.
///
/// Un seul widget pour les deux editeurs qui en ont un — le lieu et la page de
/// garde. Deux copies auraient fini par dire deux choses differentes de la
/// meme image.
///
/// Le chemin reste saisissable au clavier ; [catalog] ajoute le bouton qui
/// ouvre les images du depot, et permet de signaler une image qui n'y est
/// pas : le jeu, compile a partir du depot, ne l'aurait pas.
class PictureField extends StatefulWidget {
  const PictureField({
    required this.controller,
    required this.fieldKey,
    this.catalog,
    this.contentSource,
    this.helperText,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;

  /// La cle du champ de saisie, pour les tests.
  final Key fieldKey;

  /// Les images du depot. Nul, le champ reste seul : c'est le cas des tests
  /// qui ne portent pas sur l'image.
  final PictureCatalog? catalog;

  /// D'ou lire l'apercu. Nulle, le bundle.
  final ContentSource? contentSource;

  final String? helperText;

  /// Appele a chaque changement du chemin, saisi ou choisi.
  final VoidCallback? onChanged;

  @override
  State<PictureField> createState() => _PictureFieldState();
}

class _PictureFieldState extends State<PictureField> {
  /// Lu une fois : le depot ne change pas pendant que l'outil tourne, il
  /// faut le recompiler pour y voir une image nouvelle.
  late final Future<List<String>>? _available = widget.catalog?.listPictures();

  String get _path => widget.controller.text.trim();

  Future<void> _choose() async {
    final catalog = widget.catalog;
    if (catalog == null) return;

    final chosen = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => PictureChooserPage(catalog: catalog),
      ),
    );
    if (chosen == null || !mounted) return;

    setState(() => widget.controller.text = chosen);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          key: widget.fieldKey,
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: 'Chemin de l\'image',
            hintText: 'pictures/…',
            helperText: widget.helperText,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) {
            setState(() {});
            widget.onChanged?.call();
          },
        ),
        if (widget.catalog != null) ...<Widget>[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _choose,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choisir une image'),
            ),
          ),
        ],
        if (path.isNotEmpty && _available != null)
          FutureBuilder<List<String>>(
            future: _available,
            builder: (context, snapshot) {
              final available = snapshot.data;
              if (available == null || available.contains(path)) {
                return const SizedBox.shrink();
              }
              return _Warning(
                'Cette image n\'est pas dans le dépôt '
                '(« assets/content/pictures/ ») : le jeu ne l\'affichera pas. '
                'Choisissez-en une dans le dépôt.',
              );
            },
          ),
        if (path.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ContentImage(
              path: path,
              source: widget.contentSource,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stack) => const _Warning(
                'Image introuvable — le jeu affichera un fond uni.',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      ),
    );
  }
}
