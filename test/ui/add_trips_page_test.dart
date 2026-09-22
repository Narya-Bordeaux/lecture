import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/ui/pages/add_trips_page.dart';

/// Ajouter des trajets : le nom du trajet, et celui du lieu qu'il atteint.
///
/// **Ce sont deux choses.** « En bus » est ce que l'enfant lit sur la zone de
/// depot ; « La gare » est le lieu ou il arrive, avec son illustration et son
/// recit. L'ecran n'en demandait qu'un et baptisait le lieu du nom du trajet :
/// il apprenait donc a l'auteur une regle que le contenu livre dement.

/// Monte l'ecran et rend les trajets qu'il produit.
Future<void> pumpAddTrips(
  WidgetTester tester, {
  Map<String, String> existingEndings = const <String, String>{},
  void Function(List<NewTrip>? trips)? onResult,
}) async {
  // Deux champs par trajet, plus les trois natures expliquees : la fenetre de
  // test par defaut ne montre pas le bas de l'ecran, et un `ListView` ne
  // construit pas ce qui n'est pas visible.
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final trips = await Navigator.of(context).push<List<NewTrip>>(
              MaterialPageRoute<List<NewTrip>>(
                builder: (_) => AddTripsPage(
                  locationName: 'Devant la maison',
                  existingEndings: existingEndings,
                ),
              ),
            );
            onResult?.call(trips);
          },
          child: const Text('ouvrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

Finder tripField() => find.byKey(const Key('trip-name-0'));
Finder locationField() => find.byKey(const Key('location-name-0'));

Future<void> create(WidgetTester tester) async {
  await tester.tap(find.text('Créer'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('chaque trajet a deux champs', (tester) async {
    await pumpAddTrips(tester);

    expect(tripField(), findsOneWidget);
    expect(locationField(), findsOneWidget);
  });

  testWidgets('le lieu suit le trajet tant qu\'on n\'y touche pas',
      (tester) async {
    // Le cas courant : « À pied » mene a un lieu qu'on appellera « À pied ».
    // Obliger a saisir deux fois la meme chose serait une corvee.
    await pumpAddTrips(tester);
    await tester.enterText(tripField(), 'La gare');
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(locationField()).controller!.text,
      'La gare',
    );
  });

  testWidgets('un lieu saisi a la main cesse de suivre le trajet',
      (tester) async {
    await pumpAddTrips(tester);
    await tester.enterText(tripField(), 'En bus');
    await tester.pumpAndSettle();
    await tester.enterText(locationField(), 'La gare');
    await tester.pumpAndSettle();

    // Retaper le trajet ne doit plus ecraser le nom du lieu : l'auteur l'a
    // choisi, et le voir disparaitre en corrigeant une faute de frappe serait
    // incomprehensible.
    await tester.enterText(tripField(), 'En autocar');
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(locationField()).controller!.text,
      'La gare',
    );
  });

  testWidgets('les deux noms partent ensemble', (tester) async {
    late List<NewTrip>? trips;
    await pumpAddTrips(tester, onResult: (value) => trips = value);

    await tester.enterText(tripField(), 'En bus');
    await tester.pumpAndSettle();
    await tester.enterText(locationField(), 'La gare');
    await tester.pumpAndSettle();
    await create(tester);

    expect(trips, hasLength(1));
    expect(trips!.single.name, 'En bus');
    expect(trips!.single.locationName, 'La gare');
  });

  testWidgets('rejoindre une fin deja ecrite retire le champ du lieu',
      (tester) async {
    // Le lieu existe : son nom n'est pas a saisir, et le proposer laisserait
    // croire qu'on peut le renommer d'ici.
    await pumpAddTrips(
      tester,
      existingEndings: const <String, String>{'plage': 'La plage'},
    );

    await tester.tap(find.text('Une fin'));
    await tester.pumpAndSettle();
    expect(locationField(), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('La plage').last);
    await tester.pumpAndSettle();

    expect(locationField(), findsNothing);
  });
}
