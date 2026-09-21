import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/ui/pages/outline_page.dart';

import '../support/disk_content.dart';

/// L'ecran de construction du parcours, monte sur le contenu reel.
///
/// Le contenu se charge dans `setUpAll` : `pumpAndSettle` fait avancer une
/// horloge simulee, ou une lecture de fichier reelle ne se resout jamais, et
/// le test tournerait sans fin.

Future<void> pumpOutline(WidgetTester tester, Adventure adventure) async {
  // Un `ListView` ne construit que les cartes visibles : sur la fenetre de
  // test par defaut, les lieux du bas n'existeraient pas dans l'arbre et les
  // recherches echoueraient sans que rien ne soit casse. On regarde donc tout
  // le parcours d'un coup.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: OutlinePage(adventure: adventure)),
  );
  await tester.pumpAndSettle();
}

/// Ajoute un trajet depuis le premier point de l'ecran.
Future<void> addTripFromStart(WidgetTester tester, String name) async {
  final button = find.text('Ajouter').evaluate().isNotEmpty
      ? find.text('Ajouter')
      : find.text('Ajouter des trajets');
  await tester.tap(button.first);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, name);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Créer'));
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
    });

    testWidgets('chaque arrivee a sa propre carte plus bas', (tester) async {
      await pumpOutline(tester, realAdventure);

      // « B1 » paraît deux fois : sous le trajet qui y mene, et en tete de la
      // carte de ce lieu. C'est ce qui permet de le prolonger.
      expect(find.text('B1'), findsNWidgets(2));
      expect(find.text('B2'), findsNWidgets(2));
      expect(find.text('B3'), findsNWidgets(2));

      // Les lieux d'arrivee sont bien la, avec leur nom.
      expect(find.text('La gare'), findsWidgets);
      expect(find.text('Le garage'), findsWidgets);
      expect(find.text('La rue'), findsWidgets);
    });

    testWidgets('un lieu sans trajet le dit, et propose d\'en ajouter',
        (tester) async {
      await pumpOutline(tester, realAdventure);

      // « La rue », « Le garage » et « La plage » sont des fins : elles
      // l'annoncent, et proposent quand meme de prolonger la journee.
      expect(find.text('Fin de l\'aventure.'), findsWidgets);
      expect(find.text('Ajouter des trajets'), findsWidgets);
    });

    testWidgets('une aventure jouable ne montre aucune alerte', (tester) async {
      await pumpOutline(tester, realAdventure);

      expect(find.text('Cette aventure est jouable.'), findsOneWidget);
      expect(find.textContaining('à corriger'), findsNothing);
    });
  });

  group('Ajouter des trajets', () {
    testWidgets('l\'arrivee devient une carte en dessous', (tester) async {
      await pumpOutline(tester, realAdventure);
      await addTripFromStart(tester, 'En vélo');

      // Le trajet sous le depart, et la carte de son arrivee plus bas : c'est
      // exactement ce qui manquait, et qui rendait l'ecran inutilisable.
      expect(find.text('En vélo'), findsNWidgets(2));
      expect(find.text('B4'), findsNWidgets(2));
      expect(
        find.text('Aucun trajet ne part d\'ici pour l\'instant.'),
        findsWidgets,
      );
    });

    testWidgets('on prolonge aussitot le lieu qui vient de naitre',
        (tester) async {
      // Sur une aventure neuve, le lieu qui vient de naitre est le seul sans
      // trajet : son bouton est donc le seul a dire « Ajouter des trajets ».
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Le seuil',
      );
      await pumpOutline(tester, fresh);
      await addTripFromStart(tester, 'En bus');

      await tester.tap(find.text('Ajouter des trajets').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Depuis « En bus »'), findsOneWidget);
    });

    testWidgets('la page d\'ajout rappelle ce qui part deja d\'ici',
        (tester) async {
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('Ajouter').first);
      await tester.pumpAndSettle();

      // Sans ce rappel, la page paraît vide alors que trois trajets existent,
      // et laisse croire qu'ils ont disparu.
      expect(
        find.textContaining('En bus, En voiture, À pied'),
        findsOneWidget,
      );
    });

    testWidgets('un lieu neuf est annonce a finir, jamais a corriger',
        (tester) async {
      await pumpOutline(tester, realAdventure);
      await addTripFromStart(tester, 'En vélo');

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

  group('Le tri unique', () {
    /// Cree une aventure neuve et y ajoute un trajet de tri unique.
    Future<void> addSingleSort(WidgetTester tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'La gare',
      );
      await pumpOutline(tester, fresh);

      await tester.tap(find.text('Ajouter des trajets').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'La boutique');
      await tester.tap(find.text('Tri unique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
    }

    testWidgets('la liste du reste n\'est pas annoncee comme un defaut',
        (tester) async {
      await addSingleSort(tester);

      // « sans issue » se lisait comme une panne, alors que cette liste est
      // la moitie du dispositif.
      expect(find.text('sans issue'), findsNothing);
      expect(find.text('le reste'), findsOneWidget);
      expect(find.text('Le reste'), findsOneWidget);
    });

    testWidgets('le lieu annonce sa mecanique', (tester) async {
      await addSingleSort(tester);

      expect(
        find.text('Tri unique : ce qui est du thème, et tout le reste.'),
        findsOneWidget,
      );
    });

    testWidgets('aucun personnage n\'est invente', (tester) async {
      await addSingleSort(tester);

      // Le personnage est un ornement : l'outil ne doit pas en poser un dont
      // l'auteur n'a pas voulu.
      expect(find.byIcon(Icons.person_outline), findsNothing);
    });

    testWidgets('on n\'y propose pas plusieurs sorties', (tester) async {
      await addSingleSort(tester);

      // La carte de la boutique porte « Ajouter », puisqu'elle a deja sa
      // liste du reste.
      await tester.tap(find.text('Ajouter').last);
      await tester.pumpAndSettle();

      expect(find.text('Combien de trajets partent d\'ici ?'), findsNothing);
      expect(
        find.textContaining('ce lieu n\'a qu\'une seule sortie'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('Clore la journée', () {
    testWidgets('les trois choix structurels sont offerts, et expliqués',
        (tester) async {
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('Ajouter').first);
      await tester.pumpAndSettle();

      expect(find.text('Plusieurs listes'), findsOneWidget);
      expect(find.text('Tri unique'), findsOneWidget);
      expect(find.text('Une fin'), findsOneWidget);
      // Ce ne sont pas trois habillages : chacun dit ce que l'enfant y fera.
      expect(
        find.text('La journée s\'arrête là. Rien n\'en repart.'),
        findsOneWidget,
      );
    });

    testWidgets('un trajet « une fin » crée un lieu déjà achevé',
        (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Le seuil',
      );
      await pumpOutline(tester, fresh);

      await tester.tap(find.text('Ajouter des trajets').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'La plage');
      await tester.tap(find.text('Une fin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      // Le seul lieu qu'on puisse créer déjà terminé : il l'annonce, et rien
      // ne le signale comme inachevé.
      expect(find.text('Fin de l\'aventure.'), findsOneWidget);
      expect(find.text('La plage'), findsNWidgets(2));
    });
  });

  group('Partir d\'une page blanche', () {
    testWidgets('une aventure neuve montre son seul point de depart',
        (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Grisbie va au marché',
        startName: 'Devant la maison',
      );
      await pumpOutline(tester, fresh);

      expect(find.text('Grisbie va au marché'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Devant la maison'), findsOneWidget);
      expect(
        find.text('Aucun trajet ne part d\'ici pour l\'instant.'),
        findsOneWidget,
      );
    });

    testWidgets('elle se construit de proche en proche', (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Le seuil',
      );
      await pumpOutline(tester, fresh);

      await tester.tap(find.text('Ajouter des trajets').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'En bus');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      // Un trajet, et son arrivee en carte : la page blanche se remplit.
      expect(find.text('En bus'), findsNWidgets(2));
      expect(find.text('B1'), findsNWidgets(2));
    });
  });
}
