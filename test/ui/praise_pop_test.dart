import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/praise_schedule.dart';
import 'package:grisbie/ui/widgets/praise_pop.dart';

/// La tete de Grisbie qui sort au bord de la boite, apres un mot bien place.

const Size _phone = Size(360, 520);

/// Une image a l'ecran.
const Duration _frame = Duration(milliseconds: 16);

void main() {
  group('Ou sort la tete', () {
    test('une boite a gauche : la tete a son coin droit, la bulle vers le '
        'centre', () {
      final placement = PraisePlacement.compute(
        zone: const Rect.fromLTWH(20, 200, 140, 80),
        scene: _phone,
      );

      expect(placement.headCenter.dx, closeTo(160, 1));
      expect(placement.headCenter.dy, closeTo(200, 1));
      expect(placement.bubbleOnLeft, isFalse);
    });

    test('une boite a droite : la tete a son coin gauche, la bulle vers le '
        'centre', () {
      final placement = PraisePlacement.compute(
        zone: const Rect.fromLTWH(200, 200, 140, 80),
        scene: _phone,
      );

      expect(placement.headCenter.dx, closeTo(200, 1));
      expect(placement.bubbleOnLeft, isTrue);
    });

    test('la tete reste dans la scene, meme d une boite collee au bord', () {
      final placement = PraisePlacement.compute(
        zone: const Rect.fromLTWH(0, 0, 360, 60),
        scene: _phone,
      );
      final half = placement.headSize / 2;

      expect(placement.headCenter.dx, inInclusiveRange(half, 360 - half));
      expect(placement.headCenter.dy, inInclusiveRange(half, 520 - half));
    });

    test('la tete se voit sans tout cacher', () {
      final placement = PraisePlacement.compute(
        zone: const Rect.fromLTWH(20, 200, 140, 80),
        scene: _phone,
      );

      expect(placement.headSize, inInclusiveRange(56, 96));
    });
  });

  group('Ce qu elle montre', () {
    Future<void> pumpPop(
      WidgetTester tester,
      Praise praise, {
      VoidCallback? onFinished,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: <Widget>[
              Positioned.fill(
                child: PraisePop(
                  praise: praise,
                  zone: const Rect.fromLTWH(20, 200, 140, 80),
                  onFinished: onFinished ?? () {},
                ),
              ),
            ],
          ),
        ),
      );
    }

    Finder head(String asset) => find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == asset,
        );

    testWidgets('la tete seule, sans bulle', (tester) async {
      await pumpPop(tester, Praise(head: PraisePop.headAssets.first));
      await tester.pump(const Duration(milliseconds: 150));

      expect(head(PraisePop.headAssets.first), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('la tete et son mot', (tester) async {
      await pumpPop(
        tester,
        Praise(head: PraisePop.headAssets.last, comment: 'Super !'),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(head(PraisePop.headAssets.last), findsOneWidget);
      expect(find.text('Super !'), findsOneWidget);
    });

    testWidgets('la tete seule passe vite', (tester) async {
      var finished = false;
      await pumpPop(
        tester,
        Praise(head: PraisePop.headAssets.first),
        onFinished: () => finished = true,
      );

      // Une premiere image lance l'horloge de l'animation.
      await tester.pump(_frame);
      await tester.pump(PraisePop.headOnlyDuration);
      expect(finished, isTrue);
    });

    testWidgets('avec un mot, elle reste le temps de le lire', (tester) async {
      var finished = false;
      await pumpPop(
        tester,
        Praise(head: PraisePop.headAssets.first, comment: 'Oui !'),
        onFinished: () => finished = true,
      );

      await tester.pump(_frame);
      await tester.pump(PraisePop.headOnlyDuration);
      expect(finished, isFalse);
      await tester.pump(
        PraisePop.withCommentDuration - PraisePop.headOnlyDuration,
      );
      expect(finished, isTrue);
    });

    testWidgets('elle ne prend aucun toucher', (tester) async {
      await pumpPop(tester, Praise(head: PraisePop.headAssets.first));
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        find.ancestor(
          of: head(PraisePop.headAssets.first),
          matching: find.byWidgetPredicate(
            (widget) => widget is IgnorePointer && widget.ignoring,
          ),
        ),
        findsWidgets,
      );
    });
  });
}
