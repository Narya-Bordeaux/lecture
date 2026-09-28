import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/ui/widgets/picture_orientation_badge.dart';

/// Le badge des vignettes de la galerie : le sens de l'image, que le
/// recadrage au carre efface, et ses dimensions.
Future<void> pumpBadge(WidgetTester tester, int width, int height) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: PictureOrientationBadge(width: width, height: height),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('une image horizontale le dit, avec ses dimensions', (
    tester,
  ) async {
    await pumpBadge(tester, 1536, 1024);

    expect(find.byIcon(Icons.crop_landscape), findsOneWidget);
    expect(find.text('1536 × 1024'), findsOneWidget);
    expect(find.byTooltip('Horizontale'), findsOneWidget);
  });

  testWidgets('une image verticale le dit', (tester) async {
    await pumpBadge(tester, 1024, 1536);

    expect(find.byIcon(Icons.crop_portrait), findsOneWidget);
    expect(find.byTooltip('Verticale'), findsOneWidget);
  });

  testWidgets('une image carree le dit', (tester) async {
    await pumpBadge(tester, 1024, 1024);

    expect(find.byIcon(Icons.crop_square), findsOneWidget);
    expect(find.byTooltip('Carrée'), findsOneWidget);
  });
}
