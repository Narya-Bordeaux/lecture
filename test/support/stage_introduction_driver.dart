import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/stage_introduction.dart';
import 'package:grisbie/ui/widgets/family_intro_card.dart';
import 'package:grisbie/ui/widgets/statement_popup.dart';

/// Traverse la mise en place d'un lieu comme l'enfant : le decor seul, la
/// fleche de l'enonce, puis un toucher par boite presentee.
///
/// Les tests qui portent sur le jeu lui-meme commencent par la : les mots ne
/// bougent qu'une fois toutes les boites rangees.
Future<void> completeStageIntroduction(WidgetTester tester) async {
  await tester.pump(StageIntroduction.backgroundOnlyDuration);
  await tester.pumpAndSettle();

  final close = find.byKey(StatementPopup.closeKey);
  if (close.evaluate().isNotEmpty) {
    await tester.tap(close);
    await tester.pumpAndSettle();
  }

  // Une boite a la fois : chaque toucher en range une et presente la
  // suivante. La borne evite une boucle sans fin si rien ne se range.
  for (var guard = 0; guard < 20; guard++) {
    final card = find.byType(FamilyIntroCard);
    if (card.evaluate().isEmpty) return;
    await tester.tap(card, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  fail('La mise en place ne se termine pas.');
}
