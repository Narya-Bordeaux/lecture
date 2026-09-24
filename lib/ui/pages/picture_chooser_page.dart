import 'package:flutter/material.dart';
import 'package:grisbie/domain/repositories/picture_catalog.dart';
import 'package:grisbie/ui/widgets/content_image.dart';

/// Choisir une illustration parmi celles du depot.
///
/// Chaque image est montree en vignette avec son nom de fichier : c'est ce nom
/// que l'auteur a donne en la versant, et c'est par lui qu'il la reconnait.
/// Rend le chemin choisi (`pictures/…`), ou `null` si l'auteur renonce.
class PictureChooserPage extends StatefulWidget {
  const PictureChooserPage({required this.catalog, super.key});

  final PictureCatalog catalog;

  @override
  State<PictureChooserPage> createState() => _PictureChooserPageState();
}

class _PictureChooserPageState extends State<PictureChooserPage> {
  late final Future<List<String>> _pictures = widget.catalog.listPictures();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir une image')),
      body: FutureBuilder<List<String>>(
        future: _pictures,
        builder: (context, snapshot) {
          final pictures = snapshot.data;
          if (pictures == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (pictures.isEmpty) {
            // Dit ou verser, et ce qu'il faut faire ensuite : sans quoi
            // l'auteur chercherait un bouton d'import qui n'existe pas.
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucune image dans le dépôt. Versez vos images dans '
                  '« assets/content/pictures/ », puis recompilez l\'outil.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return GridView.extent(
            maxCrossAxisExtent: 220,
            padding: const EdgeInsets.all(12),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: <Widget>[
              for (final path in pictures)
                _PictureTile(
                  path: path,
                  onTap: () => Navigator.of(context).pop(path),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PictureTile extends StatelessWidget {
  const _PictureTile({required this.path, required this.onTap});

  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // Le bundle, et lui seul : c'est ce que le jeu montrera. La
              // vignette remplit sa case, quelles que soient les proportions.
              child: SizedBox.expand(
                child: ContentImage(
                  path: path,
                  fit: BoxFit.cover,
                  // La raison s'ecrit dans la vignette : une icone seule laissait
                  // chercher a l'aveugle pourquoi l'image ne venait pas.
                  errorBuilder: (context, error, stack) => ColoredBox(
                    color: const Color(0xFFE0E0E0),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.broken_image_outlined),
                          const SizedBox(height: 6),
                          Text(
                            describeImageError(error),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fileNameOf(path),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Le nom du fichier, sans le dossier.
String fileNameOf(String path) => path.substring(path.lastIndexOf('/') + 1);
