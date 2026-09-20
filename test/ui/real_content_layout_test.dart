import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_game/domain/models/adventure.dart';
import 'package:reading_game/domain/models/stage.dart';
import 'package:reading_game/ui/pages/stage_page.dart';
import 'package:reading_game/ui/strings/ui_strings_fr.dart';

/// Ces tests montent l'interface avec le contenu reellement livre, aux
/// coordonnees reelles de ses zones.
///
/// Ils existent pour une raison precise : le bandeau des mots, en haut, peut
/// recouvrir une zone ancree haut dans l'illustration — celle du bus commence
/// vers 29 % de la hauteur. Le doigt est alors intercepte par le bandeau et le
/// mot n'atteint jamais sa cible, sans que rien ne le signale. Une etape jouee
/// aux vraies coordonnees est le seul moyen de s'en apercevoir.

/// L'etape de depart, privee de son illustration : l'image n'est pas dans le
/// bundle de test, et seule la geometrie des zones est en cause ici.
Stage loadHomeStageWithoutBackground() {
  final file = File('assets/content/adventures/grisbie_beach.json');
  final adventure = Adventure.fromJson(
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
  );
  return adventure.startStage.copyWith(backgroundAsset: '');
}

Future<void> pumpRealStage(WidgetTester tester, Size screen) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: StagePage(
        stage: loadHomeStageWithoutBackground(),
        onDeparture: (_) {},
        random: Random(3),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> dragWordOnto(
  WidgetTester tester, {
  required String word,
  required String familyLabel,
}) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.text(word).first),
  );
  await gesture.moveBy(const Offset(0, 40));
  await tester.pump();
  await gesture.moveTo(tester.getCenter(find.text(familyLabel).first));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  // Trois formats courants, du plus contraint au plus confortable.
  const formats = <String, Size>{
    'petit telephone': Size(360, 640),
    'telephone courant': Size(390, 844),
    'tablette': Size(768, 1024),
  };

  formats.forEach((name, screen) {
    group('Sur $name (${screen.width.toInt()}x${screen.height.toInt()})', () {
      testWidgets('le bandeau des mots ne recouvre aucune zone de depot', (
        tester,
      ) async {
        await pumpRealStage(tester, screen);

        // On mesure le bandeau entier, pas son titre : c'est sa surface qui
        // intercepte le doigt.
        final trayRect = tester.getRect(find.byKey(StagePage.wordTrayKey));

        // Et la zone de depot entiere, pas son etiquette : le cadre commence
        // bien au-dessus du texte qu'il contient.
        for (final zone in find.byType(DragTarget<String>).evaluate()) {
          final box = zone.renderObject! as RenderBox;
          final zoneRect = box.localToGlobal(Offset.zero) & box.size;
          expect(
            zoneRect.top,
            greaterThanOrEqualTo(trayRect.bottom),
            reason: 'Une zone de depot passe sous le bandeau des mots '
                '(zone $zoneRect, bandeau $trayRect) : le doigt y serait '
                'intercepte avant d\'atteindre la zone.',
          );
        }
      });

      testWidgets('un mot peut etre depose dans la zone du bus', (
        tester,
      ) async {
        await pumpRealStage(tester, screen);

        await dragWordOnto(tester, word: 'arrêt', familyLabel: 'En bus');

        expect(
          find.text(UiStringsFr.familyProgress(1, 2)),
          findsOneWidget,
          reason: 'Le depot dans la zone la plus haute n\'a pas abouti',
        );
      });

      testWidgets('le parcours complet vers le bus reste jouable', (
        tester,
      ) async {
        await pumpRealStage(tester, screen);

        await dragWordOnto(tester, word: 'arrêt', familyLabel: 'En bus');
        await dragWordOnto(tester, word: 'ticket', familyLabel: 'En bus');

        expect(find.text(UiStringsFr.departTo('en bus')), findsOneWidget);
      });
    });
  });
}
