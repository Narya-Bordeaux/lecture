import 'package:flutter/material.dart';
import 'package:grisbie/application/adventure_wheel.dart';
import 'package:grisbie/application/home_layout.dart';
import 'package:grisbie/domain/models/content_index.dart';
import 'package:grisbie/domain/repositories/adventure_repository.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/ui/pages/adventure_page.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';
import 'package:grisbie/ui/widgets/content_image.dart';
import 'package:grisbie/ui/widgets/curved_text.dart';

/// L'accueil du jeu : le titre en arche, le logo, et la roue des aventures.
///
/// D'apres le croquis de l'auteur. La page ne decide rien : [HomeLayout] dit
/// ou poser chaque chose, [AdventureWheel] quelle aventure occupe quelle
/// place. Elle traduit le glissement du doigt en crans, anime le calage au
/// lacher, et ouvre l'aventure touchee.
///
/// Un toucher bref ouvre l'aventure, un glissement fait seulement tourner la
/// roue : c'est l'arene des gestes de Flutter qui les departage.
class GameHomePage extends StatefulWidget {
  const GameHomePage({
    required this.repository,
    this.contentSource,
    super.key,
  });

  /// Le logo : un element du jeu, pas du contenu d'aventure. Carre, il est
  /// decoupe en ovale a l'ecran — n'importe quelle image carree convient.
  static const String logoAsset = 'assets/accueil.jpg';

  /// Le fond de l'ecran, un bleu doux choisi par l'auteur.
  static const Color backgroundColor = Color(0xFFDCEBF7);

  /// Le titre du jeu et ceux des aventures.
  static const Color titleColor = Color(0xFF1F4B7A);

  /// Ce que le jeu propose : le sommaire seul, les aventures ne se chargent
  /// qu'une fois choisies.
  final AdventureRepository repository;

  /// D'ou lire les vignettes. Nulle, le bundle : c'est le cas du jeu.
  final ContentSource? contentSource;

  @override
  State<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends State<GameHomePage>
    with SingleTickerProviderStateMixin {
  late final Future<ContentIndex> _index = widget.repository.loadIndex();

  /// La rotation de la roue, en crans. Seule donnee propre a l'ecran : la
  /// roue en est deduite a chaque image.
  double _rotation = 0;

  late final AnimationController _settling = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..addListener(_followSettling);

  Animation<double>? _settleAnimation;

  @override
  void dispose() {
    _settling.dispose();
    super.dispose();
  }

  void _followSettling() {
    final animation = _settleAnimation;
    if (animation != null) setState(() => _rotation = animation.value);
  }

  AdventureWheel _wheelFor(int count) =>
      AdventureWheel(itemCount: count, rotation: _rotation);

  void _drag(DragUpdateDetails details, int count, HomeLayout layout) {
    _settling.stop();
    // Glisser vers la droite fait venir les aventures de gauche : la
    // rotation diminue.
    final turned = _wheelFor(count).turnedBy(
      -details.delta.dx / layout.slotSpacing,
    );
    setState(() => _rotation = turned.rotation);
  }

  void _release(DragEndDetails details, int count, HomeLayout layout) {
    final target = _wheelFor(count)
        .settled(velocity: -details.velocity.pixelsPerSecond.dx /
            layout.slotSpacing)
        .rotation;
    _settleAnimation = Tween<double>(begin: _rotation, end: target).animate(
      CurvedAnimation(parent: _settling, curve: Curves.easeOutCubic),
    );
    _settling.forward(from: 0);
  }

  void _open(AdventureEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => AdventurePage(
          repository: widget.repository,
          adventureId: entry.id,
          onFinished: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameHomePage.backgroundColor,
      body: SafeArea(
        child: FutureBuilder<ContentIndex>(
          future: _index,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _Message(UiStringsFr.loadingFailed);
            }
            final index = snapshot.data;
            if (index == null) return _Message(UiStringsFr.loading);

            return LayoutBuilder(
              builder: (context, constraints) {
                final layout = HomeLayout.compute(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                );
                return _buildHome(layout, index.adventures);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHome(HomeLayout layout, List<AdventureEntry> adventures) {
    final count = adventures.length;
    final wheel = _wheelFor(count);
    final titleStyle = TextStyle(
      fontSize: layout.titleFontSize,
      fontWeight: FontWeight.w800,
      color: GameHomePage.titleColor,
      height: 1,
    );
    final logoCenter = Offset(layout.logoCenterX, layout.logoCenterY);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (details) => _drag(details, count, layout),
      onHorizontalDragEnd: (details) => _release(details, count, layout),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Semantics(
              header: true,
              label: UiStringsFr.appTitle,
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: _TitlePainter(
                    first: CurvedTextPainter(
                      text: UiStringsFr.homeTitleFirstLine,
                      style: titleStyle,
                      center: logoCenter,
                      radius: layout.titleOuterRadius,
                    ),
                    second: CurvedTextPainter(
                      text: UiStringsFr.homeTitleSecondLine,
                      style: titleStyle,
                      center: logoCenter,
                      radius: layout.titleInnerRadius,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: layout.logoCenterX - layout.logoWidth / 2,
            top: layout.logoCenterY - layout.logoHeight / 2,
            width: layout.logoWidth,
            height: layout.logoHeight,
            child: const _Logo(),
          ),
          for (final slot in wheel.slots)
            _placeCard(layout, slot, adventures[slot.itemIndex]),
        ],
      ),
    );
  }

  Widget _placeCard(HomeLayout layout, WheelSlot slot, AdventureEntry entry) {
    final placement = layout.arc.place(slot.position);

    return Positioned(
      key: ValueKey<String>(entry.id),
      left: placement.x - layout.cardWidth / 2,
      top: placement.y - layout.elementHeight / 2,
      width: layout.cardWidth,
      height: layout.elementHeight,
      child: Transform.rotate(
        angle: placement.tilt,
        child: Opacity(
          opacity: slot.visibility,
          child: _AdventureCard(
            entry: entry,
            layout: layout,
            contentSource: widget.contentSource,
            // Une vignette qui entre ou sort ne s'ouvre pas : elle est a
            // moitie hors de l'arc, l'enfant ne la visait pas.
            onTap: slot.visibility == 1 ? () => _open(entry) : null,
          ),
        ),
      ),
    );
  }
}

/// Les deux lignes du titre, peintes l'une apres l'autre.
class _TitlePainter extends CustomPainter {
  _TitlePainter({required this.first, required this.second});

  final CurvedTextPainter first;
  final CurvedTextPainter second;

  @override
  void paint(Canvas canvas, Size size) {
    first.paint(canvas, size);
    second.paint(canvas, size);
  }

  @override
  bool shouldRepaint(_TitlePainter oldDelegate) =>
      first.shouldRepaint(oldDelegate.first) ||
      second.shouldRepaint(oldDelegate.second);
}

/// Le logo, decoupe en ovale et cercle de blanc.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: OvalBorder(side: BorderSide(color: Colors.white, width: 4)),
        shadows: <BoxShadow>[
          BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipOval(
          child: Image.asset(
            GameHomePage.logoAsset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

/// Une aventure sur la roue : sa vignette, et son titre dessous.
class _AdventureCard extends StatelessWidget {
  const _AdventureCard({
    required this.entry,
    required this.layout,
    required this.onTap,
    this.contentSource,
  });

  final AdventureEntry entry;
  final HomeLayout layout;
  final VoidCallback? onTap;
  final ContentSource? contentSource;

  @override
  Widget build(BuildContext context) {
    final cover = entry.coverAsset;

    return Semantics(
      button: true,
      label: UiStringsFr.adventureSemantics(entry.title),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: <Widget>[
            Container(
              width: layout.cardWidth,
              height: layout.cardHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                // Recadree au centre si elle n'est pas en 3:2 : c'est le seul
                // recadrage du jeu, et l'outil d'auteur le signale.
                child: cover == null
                    ? const SizedBox.expand()
                    : ContentImage(
                        path: cover,
                        source: contentSource,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            const SizedBox.expand(),
                      ),
              ),
            ),
            const SizedBox(height: HomeLayout.captionGap),
            SizedBox(
              height: layout.captionHeight,
              child: ExcludeSemantics(
                child: Text(
                  entry.title,
                  textAlign: TextAlign.center,
                  maxLines: HomeLayout.captionLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: layout.captionFontSize,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: GameHomePage.titleColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, color: GameHomePage.titleColor),
      ),
    );
  }
}
