import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/ui/widgets/family_drop_zone.dart';
import 'package:grisbie/ui/widgets/word_label.dart';

/// L'etiquette posable qui porte [word].
Finder wordLabelFinder(String word) {
  return find
      .ancestor(of: find.text(word), matching: find.byType(DraggableWordLabel))
      .first;
}

/// Fait glisser l'etiquette [word] de sorte que **le mot**, et non le doigt,
/// arrive a [target] — comme l'enfant, qui regarde son mot et pas sa main.
///
/// Le mot se tient au-dessus du doigt : pour le poser en [target], le doigt
/// vise un peu plus bas. [settle] a faux laisse le geste en cours
/// d'animation, pour observer ce qui suit le lacher.
Future<void> dragWordTo(
  WidgetTester tester, {
  required String word,
  required Offset target,
  bool settle = true,
}) async {
  final label = wordLabelFinder(word);
  final seenPoint = DraggableWordLabel.seenPointFromFinger(
    tester.getSize(label),
  );

  final gesture = await tester.startGesture(tester.getCenter(label));
  // Un premier deplacement declenche la prise en main, avant de viser.
  await gesture.moveBy(const Offset(0, 40));
  await tester.pump();
  await gesture.moveTo(target - seenPoint);
  await tester.pump();
  await gesture.up();
  if (settle) await tester.pumpAndSettle();
}

/// Fait glisser l'etiquette [word] jusqu'au centre du cadre [familyId].
///
/// On vise le cadre et non l'intitule : celui-ci est pose au-dessus de la
/// zone, et n'est donc pas un point de depot.
Future<void> dragWordOnto(
  WidgetTester tester, {
  required String word,
  required String familyId,
}) async {
  await dragWordTo(
    tester,
    word: word,
    target: tester.getCenter(find.byKey(FamilyDropZone.frameKeyFor(familyId))),
  );
}
