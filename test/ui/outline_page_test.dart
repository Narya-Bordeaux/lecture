import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/ui/pages/add_trips_page.dart';
import 'package:grisbie/ui/pages/outline_page.dart';

import '../support/disk_content.dart';

/// L'ecran de construction du parcours, monte sur le contenu reel.
///
/// Le contenu se charge dans `setUpAll` : `pumpAndSettle` fait avancer une
/// horloge simulee, ou une lecture de fichier reelle ne se resout jamais, et
/// le test tournerait sans fin.

Future<void> pumpOutline(WidgetTester tester, Adventure adventure) async {
  await tester.pumpWidget(
    MaterialApp(home: OutlinePage(adventure: adventure)),
  );
  await tester.pumpAndSettle();
}

void main() {
  late Adventure realAdventure;

  setUpAll(() async {
    realAdventure = await loadRealAdventure();
  });

  group('Ce que l\'ecran montre', () {
    testWidgets('le depart porte sa lettre et son nom', (tester) async {
      await pumpOutline(tester, realAdventure);

      expect(find.text('A'), findsOneWidget);
      expect(find.text('Devant la maison'), findsOneWidget);
    });

    testWidgets('les trajets du depart se lisent sous lui', (tester) async {
      await pumpOutline(tester, realAdventure);

      expect(find.text('En bus'), findsOneWidget);
      expect(find.text('En voiture'), findsOneWidget);
      expect(find.text('À pied'), findsOneWidget);
      // Chacun montre le reperage de son arrivee. « B1 » paraît deux fois :
      // sous le trajet qui y mene, et en tete du bloc de la gare, qui se
      // deploie a son tour. « B3 » est la rue, qui ne se deploie pas encore.
      expect(find.text('B1'), findsNWidgets(2));
      expect(find.text('B3'), findsOneWidget);
    });

    testWidgets('une aventure jouable ne montre aucune alerte', (tester) async {
      await pumpOutline(tester, realAdventure);

      expect(find.text('Cette aventure est jouable.'), findsOneWidget);
      expect(find.textContaining('à corriger'), findsNothing);
    });

    testWidgets('chaque point offre d\'ajouter la suite', (tester) async {
      await pumpOutline(tester, realAdventure);

      // Un bouton par point qui se deploie : maison, gare, boutique.
      expect(find.text('Ajouter'), findsWidgets);
    });
  });

  group('Ajouter des trajets', () {
    testWidgets('le parcours s\'allonge, et le lettrage suit', (tester) async {
      await pumpOutline(tester, realAdventure);

      // Depuis le depart, qui propose deja trois directions.
      await tester.tap(find.text('Ajouter').first);
      await tester.pumpAndSettle();

      expect(find.byType(AddTripsPage), findsOneWidget);
      expect(find.textContaining('Devant la maison'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'En vélo');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      // Le trajet apparait sous le depart, avec la lettre de son arrivee.
      expect(find.text('En vélo'), findsOneWidget);
      expect(find.text('B4'), findsOneWidget);
    });

    testWidgets('un lieu neuf est annonce a finir, jamais a corriger',
        (tester) async {
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('Ajouter').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'En vélo');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      // C'est tout l'interet de la distinction : ecrire ne doit pas produire
      // d'ecran rouge, sans quoi on apprendrait a l'ignorer.
      expect(find.textContaining('à finir'), findsOneWidget);
      expect(find.textContaining('à corriger'), findsNothing);
    });

    testWidgets('on choisit combien de trajets partent du point',
        (tester) async {
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('Ajouter').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('sans nom saisi, rien ne se cree', (tester) async {
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('Ajouter').first);
      await tester.pumpAndSettle();

      // Mieux vaut un trajet de moins qu'un lieu appele « lieu ».
      final create = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Créer'),
          matching: find.byType(TextButton),
        ),
      );
      expect(create.onPressed, isNull);
    });
  });
}
