import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/picture_folder.dart';
import 'package:grisbie/domain/repositories/picture_catalog.dart';
import 'package:grisbie/ui/widgets/content_image.dart';

/// Choisir une illustration parmi celles du depot.
///
/// Chaque image est montree en vignette avec son nom de fichier : c'est ce nom
/// que l'auteur a donne en la versant, et c'est par lui qu'il la reconnait.
/// Rend le chemin choisi (`pictures/…`), ou `null` si l'auteur renonce.
///
/// **Le choix s'ouvre sur le dossier de l'aventure** (`pictures/<id>/`, voir
/// [PictureFolder]) : tout dans une seule grille devenait ingerable des la
/// seconde aventure. Les autres dossiers se montrent a la demande, chacun sous
/// son nom — une image partagee reste a portee.
class PictureChooserPage extends StatefulWidget {
  const PictureChooserPage({
    required this.catalog,
    this.adventureId,
    super.key,
  });

  final PictureCatalog catalog;

  /// L'aventure en cours, dont le dossier s'ouvre d'abord. Nul, tout se
  /// montre.
  final String? adventureId;

  /// Le bouton qui montre tous les dossiers.
  static const String showAllLabel = 'Toutes les images';

  /// Le bouton qui revient au dossier de l'aventure.
  static const String showAdventureLabel = 'Images de cette aventure';

  /// L'intertitre des images posees a la racine de `pictures/`.
  static const String rootLabel = 'À la racine de « pictures/ »';

  @override
  State<PictureChooserPage> createState() => _PictureChooserPageState();
}

class _PictureChooserPageState extends State<PictureChooserPage> {
  late final Future<List<String>> _pictures = widget.catalog.listPictures();

  /// Vrai quand l'auteur a demande tous les dossiers.
  bool _showAll = false;

  /// Le chemin du dossier de l'aventure dans le depot, pour les messages.
  String _adventureDirectory(String adventureId) =>
      'assets/content/${PictureFolder.pathFor(adventureId)}';

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
          final adventureId = widget.adventureId;
          if (pictures.isEmpty) {
            // Dit ou verser, et ce qu'il faut faire ensuite : sans quoi
            // l'auteur chercherait un bouton d'import qui n'existe pas.
            final directory = adventureId == null
                ? 'assets/content/pictures/'
                : _adventureDirectory(adventureId);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aucune image dans le dépôt. Versez vos images dans '
                  '« $directory », puis recompilez l\'outil.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final groups = PictureFolder.group(pictures);
          final ownPictures = adventureId == null ? null : groups[adventureId];

          if (ownPictures != null && !_showAll) {
            return _buildSections(
              context,
              header: _SwitchButton(
                label: PictureChooserPage.showAllLabel,
                icon: Icons.folder_open_outlined,
                onPressed: () => setState(() => _showAll = true),
              ),
              groups: <String, List<String>>{adventureId!: ownPictures},
              withTitles: false,
            );
          }

          return _buildSections(
            context,
            header: ownPictures != null
                ? _SwitchButton(
                    label: PictureChooserPage.showAdventureLabel,
                    icon: Icons.arrow_back,
                    onPressed: () => setState(() => _showAll = false),
                  )
                : adventureId != null
                // Le dossier manque : le dire, et comment le creer. Un
                // dossier non declare n'est pas embarque par Flutter.
                ? _Notice(
                    'Aucune image dans « '
                    '${_adventureDirectory(adventureId)} ». Créez ce '
                    'dossier, déclarez-le dans pubspec.yaml, puis '
                    'recompilez l\'outil. En attendant, toutes les images '
                    'du dépôt :',
                  )
                : null,
            groups: groups,
            withTitles: true,
          );
        },
      ),
    );
  }

  /// Les images, dossier par dossier, sous un en-tete facultatif.
  Widget _buildSections(
    BuildContext context, {
    required Widget? header,
    required Map<String, List<String>> groups,
    required bool withTitles,
  }) {
    return CustomScrollView(
      slivers: <Widget>[
        if (header != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            sliver: SliverToBoxAdapter(child: header),
          ),
        for (final MapEntry(key: folder, value: paths)
            in groups.entries) ...<Widget>[
          if (withTitles)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  folder == PictureFolder.root
                      ? PictureChooserPage.rootLabel
                      : folder,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid.extent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: <Widget>[
                for (final path in paths)
                  _PictureTile(
                    path: path,
                    onTap: () => Navigator.of(context).pop(path),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Le bouton qui passe d'une vue a l'autre.
class _SwitchButton extends StatelessWidget {
  const _SwitchButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

/// Un avis en tete de liste.
class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
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
