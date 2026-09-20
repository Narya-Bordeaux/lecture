import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_game/application/stage_engine.dart';
import 'package:reading_game/domain/models/stage.dart';
import 'package:reading_game/domain/models/word.dart';
import 'package:reading_game/ui/pages/stage_page.dart';
import 'package:reading_game/ui/widgets/family_drop_zone.dart';
import 'package:reading_game/ui/strings/ui_strings_fr.dart';

import '../support/disk_content.dart';

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
late final Stage _homeStage;

Future<void> loadHomeStage() async {
  final adventure = await loadRealAdventure();
  _homeStage = adventure.startStage.copyWith(backgroundAsset: '');
}

Stage loadHomeStageWithoutBackground() => _homeStage;

/// La graine du melange, partagee entre la page et le moteur temoin.
const int _seed = 3;

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
        random: Random(_seed),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Un moteur mene en parallele, avec la meme graine que la page.
///
/// Les mots proposes sont tires d'une reserve de trente : impossible de viser
/// un mot ecrit en dur dans le test. Ce temoin dit lesquels sont a l'ecran, et
/// a quelle famille ils appartiennent.
StageEngine buildWitnessEngine() {
  return StageEngine(
    stage: loadHomeStageWithoutBackground(),
    random: Random(_seed),
  );
}

/// On vise le cadre et non l'intitule : celui-ci est pose au-dessus de la zone,
/// et n'est donc plus un point de depot valide.
Future<void> dragWordOnto(
  WidgetTester tester, {
  required String word,
  required String familyId,
}) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.text(word).first),
  );
  await gesture.moveBy(const Offset(0, 40));
  await tester.pump();
  await gesture.moveTo(
    tester.getCenter(find.byKey(FamilyDropZone.frameKeyFor(familyId))),
  );
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  // Le contenu est charge une fois : il traverse le fichier pere, les lexiques
  // et les personnages, ce qui n'a pas a etre refait a chaque test.
  setUpAll(loadHomeStage);

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

      testWidgets('aucun intitule de zone n\'est tronque', (tester) async {
        await pumpRealStage(tester, screen);

        // « En voiture » s'abregeait en « En voitu... » quand l'intitule etait
        // contraint par la largeur de son cadre. Un enfant qui apprend a lire
        // ne doit jamais voir un mot coupe.
        for (final family in loadHomeStageWithoutBackground().families) {
          final label = tester.widget<Text>(find.text(family.label));

          expect(
            label.overflow,
            TextOverflow.visible,
            reason: '"${family.label}" pourrait etre abrege',
          );
          expect(label.maxLines, 1);
          expect(label.softWrap, isFalse);

          // Le texte s'affiche a sa largeur naturelle, sans compression.
          final painted = tester.renderObject<RenderBox>(
            find.text(family.label),
          );
          final natural = (TextPainter(
            text: TextSpan(text: family.label, style: label.style),
            textDirection: TextDirection.ltr,
          )..layout())
              .width;
          expect(
            painted.size.width,
            greaterThanOrEqualTo(natural - 1),
            reason: '"${family.label}" est rendu plus etroit que son texte',
          );
        }
      });

      testWidgets('un mot peut etre depose dans chaque zone', (tester) async {
        await pumpRealStage(tester, screen);
        final witness = buildWitnessEngine();
        final stage = witness.stage;

        // Un mot par famille, pour eprouver les trois zones — dont celle du
        // bus, la plus haute et donc la plus exposee au recouvrement.
        for (final family in stage.families) {
          final word = witness.visibleWords.whereType<Word>().firstWhere(
                (word) => family.accepts(word.id),
                orElse: () => stage.findWord(family.wordIds.first)!,
              );
          if (!witness.visibleWords.contains(word)) continue;

          await dragWordOnto(
            tester,
            word: word.text,
            familyId: family.id,
          );
          witness.placeWord(wordId: word.id, familyId: family.id);

          expect(
            find.text(UiStringsFr.familyProgress(1, family.requiredCount)),
            findsWidgets,
            reason: 'Le depot dans la zone "${family.label}" n\'a pas abouti',
          );
        }
      });

      testWidgets('ouvrir un chemin reste jouable de bout en bout', (
        tester,
      ) async {
        await pumpRealStage(tester, screen);
        final witness = buildWitnessEngine();
        final family = witness.stage.families.first;

        // On classe jusqu'a l'objectif, en suivant les mots reellement
        // proposes : chaque reussite en fait apparaitre un nouveau.
        //
        // Il arrive qu'aucun mot de la famille visee ne soit a l'ecran — le
        // tirage est libre. L'enfant classe alors ailleurs, ce qui renouvelle
        // la reserve ; le test fait de meme plutot que de rester bloque.
        var safety = 0;
        while (witness.state.placedCountIn(family.id) < family.requiredCount) {
          expect(safety++, lessThan(40), reason: 'Progression impossible');

          final visible = witness.visibleWords.whereType<Word>().toList();
          expect(visible, isNotEmpty, reason: 'Plus aucun mot propose');

          final word = visible.firstWhere(
            (word) => family.accepts(word.id),
            orElse: () => visible.first,
          );
          final target = witness.stage.families.firstWhere(
            (candidate) => candidate.accepts(word.id),
          );

          await dragWordOnto(
            tester,
            word: word.text,
            familyId: target.id,
          );
          witness.placeWord(wordId: word.id, familyId: target.id);
        }

        expect(
          find.text(UiStringsFr.departTo(family.label.toLowerCase())),
          findsOneWidget,
        );
      });
    });
  });
}
