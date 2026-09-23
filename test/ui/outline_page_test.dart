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

Future<void> pumpOutline(
  WidgetTester tester,
  Adventure adventure, {
  Future<List<String>> Function(Adventure adventure)? onSave,
}) async {
  // Un `ListView` ne construit que les cartes visibles : sur la fenetre de
  // test par defaut, les lieux du bas n'existeraient pas dans l'arbre et les
  // recherches echoueraient sans que rien ne soit casse. On regarde donc tout
  // le parcours d'un coup.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: OutlinePage(adventure: adventure, onSave: onSave)),
  );
  await tester.pumpAndSettle();
}

/// Le champ du nom d'un trajet dans l'ecran d'ajout.
///
/// Chaque trajet y a **deux** champs — le trajet et le lieu ou il mene — si
/// bien que compter les `TextField` ne dit plus combien de trajets on saisit.
Finder tripField(int index) => find.byKey(Key('trip-name-$index'));

/// Ajoute un trajet depuis le premier point de l'ecran.
///
/// Un lieu deja a plusieurs listes porte « Ajouter » ; un lieu a definir pose
/// la question, et « Plusieurs listes » y repond.
Future<void> addTripFromStart(WidgetTester tester, String name) async {
  final button = find.text('Ajouter').evaluate().isNotEmpty
      ? find.text('Ajouter')
      : find.text('Plusieurs listes');
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

    testWidgets('un trajet dit ou il mene, sans avoir a chercher sa carte',
        (tester) async {
      await pumpOutline(tester, realAdventure);

      // La lettre seule obligeait a descendre chercher la carte « B1 » pour
      // apprendre que « En bus » arrive a la gare. Sur le croquis papier, la
      // fleche portait les deux bouts.
      expect(
        find.textContaining('En bus → La gare', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Acheter quelque chose → La boutique de la gare',
            findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('un trajet qui porte deja le nom du lieu ne se repete pas',
        (tester) async {
      // « En bus → En bus » serait du bruit, et se lirait comme un defaut.
      // C'est le cas de tout ce que l'outil a cree avant qu'on distingue les
      // deux noms.
      final built = AdventureBuilder(
        AdventureBuilder.createAdventure(title: 'Essai', startName: 'Maison'),
      ).addTrips('maison', const <NewTrip>[NewTrip(name: 'En bus')]);

      await pumpOutline(tester, built);

      // « En bus » paraît deux fois : la ligne du trajet, et le titre de la
      // carte du lieu qu'il a créé. Ce qui ne doit pas paraître, c'est la
      // flèche qui redirait la seconde sous la première.
      expect(find.text('En bus'), findsNWidgets(2));
      expect(find.textContaining('→', findRichText: true), findsNothing);
    });

    testWidgets('les trajets du depart se lisent sous lui', (tester) async {
      await pumpOutline(tester, realAdventure);

      // Chaque ligne porte le trajet **et** le lieu ou il mene, en un seul
      // texte enrichi : d'ou la recherche dans le texte riche.
      for (final trip in <String>['En bus', 'En voiture', 'À pied']) {
        expect(
          find.textContaining(trip, findRichText: true),
          findsOneWidget,
          reason: trip,
        );
      }
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

    testWidgets('une fin l\'annonce, et ne propose rien de plus',
        (tester) async {
      await pumpOutline(tester, realAdventure);

      // « La rue », « Le garage » et « La plage » sont des fins. Elles gardent
      // leur carte — il y aura une image et un texte a y poser — mais rien
      // n'en repart, et l'ecran ne doit pas laisser croire le contraire.
      expect(
        find.text('Fin de l\'aventure : du texte, pas de jeu.'),
        findsNWidgets(3),
      );
      expect(find.text('Que fait l\'enfant ici ?'), findsNothing);

      // Les deux lieux a plusieurs listes le proposent. La boutique, tri
      // unique, a deja sa seule sortie : rien a y ajouter.
      expect(find.text('Ajouter'), findsNWidgets(2));
    });

    testWidgets('une aventure jouable ne montre aucune alerte', (tester) async {
      await pumpOutline(tester, realAdventure);

      expect(find.text('Cette aventure est jouable.'), findsOneWidget);
      expect(find.textContaining('à corriger'), findsNothing);
    });
  });

  group('Quitter sans avoir enregistré', () {
    /// Monte l'ecran **empile**, pour qu'on puisse en sortir.
    ///
    /// Les autres tests le posent en racine : on ne quitte pas la racine, et la
    /// question ne se poserait donc jamais.
    Future<Adventure?> pumpPushedOutline(
      WidgetTester tester,
      Adventure adventure, {
      Future<List<String>> Function(Adventure adventure)? onSave,
    }) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Adventure? returned;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                returned = await Navigator.of(context).push<Adventure>(
                  MaterialPageRoute<Adventure>(
                    builder: (_) =>
                        OutlinePage(adventure: adventure, onSave: onSave),
                  ),
                );
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      return returned;
    }

    /// Ajoute un trajet, ce qui rend l'aventure differente de celle recue.
    Future<void> modify(WidgetTester tester) async {
      await addTripFromStart(tester, 'En tramway');
    }

    Future<void> goBack(WidgetTester tester) async {
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }

    testWidgets('sans rien avoir touché, on sort sans question',
        (tester) async {
      await pumpPushedOutline(tester, realAdventure);
      await goBack(tester);

      expect(find.text('Modifications non enregistrées'), findsNothing);
      expect(find.byType(OutlinePage), findsNothing);
    });

    testWidgets('après une modification, la sortie est retenue',
        (tester) async {
      // Le piege repare : « Garder » ferme un editeur et rend son resultat a
      // cet ecran, en memoire. Quitter sans enregistrer jetait tout, sans un
      // mot — et l'auteur cherchait ensuite son aventure dans la liste.
      await pumpPushedOutline(tester, realAdventure);
      await modify(tester);
      await goBack(tester);

      expect(find.text('Modifications non enregistrées'), findsOneWidget);
      expect(find.byType(OutlinePage), findsOneWidget);
    });

    testWidgets('rester referme la question et laisse le travail intact',
        (tester) async {
      await pumpPushedOutline(tester, realAdventure);
      await modify(tester);
      await goBack(tester);

      await tester.tap(find.text('Rester'));
      await tester.pumpAndSettle();

      expect(find.byType(OutlinePage), findsOneWidget);
      // Deux fois : la ligne du trajet, et la carte du lieu qu'il a créé.
      expect(
        find.textContaining('En tramway', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('quitter sans enregistrer est possible, mais se demande',
        (tester) async {
      // Renoncer a son travail reste un geste legitime — il faut seulement
      // qu'il soit voulu.
      await pumpPushedOutline(tester, realAdventure);
      await modify(tester);
      await goBack(tester);

      await tester.tap(find.text('Quitter sans enregistrer'));
      await tester.pumpAndSettle();

      expect(find.byType(OutlinePage), findsNothing);
    });

    testWidgets('enregistrer et quitter écrit, puis sort', (tester) async {
      Adventure? saved;
      await pumpPushedOutline(
        tester,
        realAdventure,
        onSave: (adventure) async {
          saved = adventure;
          return <String>['index.json'];
        },
      );
      await modify(tester);
      await goBack(tester);

      await tester.tap(find.text('Enregistrer et quitter'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.findStage('en_tramway'), isNotNull);
      expect(find.byType(OutlinePage), findsNothing);
    });

    testWidgets('sans dépôt, la question le dit et n\'offre pas d\'écrire',
        (tester) async {
      // Proposer « Enregistrer et quitter » sans nulle part ou ecrire serait
      // un bouton qui ne fait rien, au pire moment.
      await pumpPushedOutline(tester, realAdventure);
      await modify(tester);
      await goBack(tester);

      expect(find.text('Enregistrer et quitter'), findsNothing);
      expect(find.textContaining('nulle part où l\'enregistrer'), findsOneWidget);
    });

    testWidgets('enregistrer puis quitter ne repose plus la question',
        (tester) async {
      await pumpPushedOutline(
        tester,
        realAdventure,
        onSave: (adventure) async => <String>['index.json'],
      );
      await modify(tester);

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      await goBack(tester);

      expect(find.text('Modifications non enregistrées'), findsNothing);
      expect(find.byType(OutlinePage), findsNothing);
    });
  });

  group('Enregistrer', () {
    testWidgets('sans destination, aucun bouton ne le propose', (tester) async {
      // Une plateforme sans ou ecrire — ou un test — n'offre pas un geste qui
      // ne ferait rien.
      await pumpOutline(tester, realAdventure);

      expect(find.text('Enregistrer'), findsNothing);
    });

    testWidgets('c\'est l\'aventure modifiée qui part, pas celle d\'origine',
        (tester) async {
      Adventure? saved;
      await pumpOutline(
        tester,
        realAdventure,
        onSave: (adventure) async {
          saved = adventure;
          return <String>['index.json'];
        },
      );

      // On renomme un lieu, puis on enregistre : c'est tout l'interet du
      // geste, et l'ecran travaille en memoire.
      await tester.tap(find.text('Devant la maison'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Sur le perron');
      await tester.tap(find.text('Garder'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(saved!.findStage('maison')!.locationName, 'Sur le perron');
    });

    testWidgets('le compte des fichiers écrits est annoncé', (tester) async {
      await pumpOutline(
        tester,
        realAdventure,
        onSave: (adventure) async =>
            <String>['index.json', 'adventures/a.json', 'lists/a.json'],
      );

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      // Sans retour, on ne sait pas si le geste a abouti — et rien d'autre a
      // l'ecran ne change.
      expect(find.textContaining('3 fichier'), findsOneWidget);
    });

    testWidgets('un échec se dit, au lieu de passer pour un succès',
        (tester) async {
      await pumpOutline(
        tester,
        realAdventure,
        onSave: (adventure) async => throw StateError('Disque plein'),
      );

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Disque plein'), findsOneWidget);
    });
  });

  group('Ouvrir un lieu', () {
    testWidgets('cliquer le titre ouvre ce que le lieu porte', (tester) async {
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('Devant la maison'));
      await tester.pumpAndSettle();

      // Tout sauf les mots : ceux-la appartiennent au trajet.
      expect(find.text('Le lieu'), findsOneWidget);
      expect(find.text('L\'illustration'), findsOneWidget);
      expect(find.text('L\'énoncé'), findsOneWidget);
    });

    testWidgets('le lieu renommé revient sur sa carte', (tester) async {
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('Devant la maison'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Sur le perron');
      await tester.tap(find.text('Garder'));
      await tester.pumpAndSettle();

      expect(find.text('Sur le perron'), findsOneWidget);
      expect(find.text('Devant la maison'), findsNothing);
    });

    testWidgets('renoncer laisse la carte intacte', (tester) async {
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('La gare').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Perdu');
      await tester.tap(find.byTooltip('Fermer sans garder'));
      await tester.pumpAndSettle();

      expect(find.text('Perdu'), findsNothing);
      expect(find.text('La gare'), findsWidgets);
    });
  });

  group('La page de garde', () {
    testWidgets('elle se lit au-dessus du premier lieu', (tester) async {
      await pumpOutline(tester, realAdventure);

      expect(find.text('Page de garde'), findsOneWidget);
      expect(find.text('Grisbie part à la plage'), findsOneWidget);

      // Au-dessus du premier lieu, comme a l'ecran du jeu : c'est un seuil.
      final opening = tester.getTopLeft(find.text('Page de garde'));
      final first = tester.getTopLeft(find.text('Devant la maison'));
      expect(opening.dy, lessThan(first.dy));
    });

    testWidgets('sans page de garde, la carte le dit', (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Le seuil',
      );
      await pumpOutline(tester, fresh);

      expect(find.text('Page de garde'), findsOneWidget);
      expect(find.textContaining('Aucune'), findsOneWidget);
    });

    testWidgets('elle s\'écrit, et apparaît aussitôt', (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Le seuil',
      );
      await pumpOutline(tester, fresh);

      await tester.tap(find.text('Page de garde'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('openingTitle')),
        'Grisbie s\'en va',
      );
      await tester.enterText(
        find.byKey(const Key('openingText')),
        'Ce matin, il fait beau.',
      );
      await tester.tap(find.text('Garder'));
      await tester.pumpAndSettle();

      expect(find.text('Grisbie s\'en va'), findsOneWidget);
    });

    testWidgets('elle se retire, sans quoi elle serait un cul-de-sac',
        (tester) async {
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('Page de garde'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer la page de garde'));
      await tester.pumpAndSettle();

      expect(find.text('Grisbie part à la plage'), findsNothing);
      expect(find.textContaining('Aucune'), findsOneWidget);
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
    });

    testWidgets('le lieu qui vient de naitre demande ce qu\'on y fait',
        (tester) async {
      await pumpOutline(tester, realAdventure);
      await addTripFromStart(tester, 'En vélo');

      // La nature se decide sur la carte du lieu, pas au moment de le creer.
      expect(find.text('Que fait l\'enfant ici ?'), findsOneWidget);
    });

    testWidgets('on prolonge aussitot le lieu qui vient de naitre',
        (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Le seuil',
      );
      await pumpOutline(tester, fresh);
      await addTripFromStart(tester, 'En bus');

      // Le seuil a maintenant ses listes ; seul le lieu neuf pose la question.
      await tester.tap(find.text('Plusieurs listes').first);
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
      expect(find.text('Cette aventure n\'est pas complète.'), findsOneWidget);
      expect(find.textContaining('à finir'), findsOneWidget);
      expect(find.textContaining('à corriger'), findsNothing);
      expect(find.text('Cette aventure est jouable.'), findsNothing);
    });

    testWidgets('on choisit combien de trajets partent du point',
        (tester) async {
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('Ajouter').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      expect(tripField(2), findsOneWidget);
      expect(tripField(3), findsNothing);
    });

    testWidgets('la page d\'ajout ne redemande pas la nature', (tester) async {
      // Elle a ete dite sur la carte : la reposer ici, trajet par trajet,
      // laissait croire qu'elle portait sur le chemin.
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('Ajouter').first);
      await tester.pumpAndSettle();

      expect(find.text('Tri unique'), findsNothing);
      expect(find.text('Une fin'), findsNothing);
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

  group('Que fait l\'enfant ici ?', () {
    testWidgets('un lieu a definir offre les trois reponses', (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'La gare',
      );
      await pumpOutline(tester, fresh);

      expect(find.text('Que fait l\'enfant ici ?'), findsOneWidget);
      expect(find.text('Plusieurs listes'), findsOneWidget);
      expect(find.text('Tri unique'), findsOneWidget);
      expect(find.text('Une fin'), findsOneWidget);
    });

    testWidgets('un lieu defini ne repose plus la question', (tester) async {
      await pumpOutline(tester, realAdventure);

      expect(find.text('Que fait l\'enfant ici ?'), findsNothing);
    });
  });

  group('Le tri unique', () {
    /// Une aventure neuve dont le depart devient un tri unique.
    Future<void> defineSingleSort(WidgetTester tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'La boutique',
      );
      await pumpOutline(tester, fresh);

      await tester.tap(find.text('Tri unique'));
      await tester.pumpAndSettle();
      await tester.enterText(tripField(0), 'Ce qui se mange');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('location-name-0')),
        'La plage',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
    }

    testWidgets('on n\'y choisit pas de nombre : une seule sortie',
        (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'La boutique',
      );
      await pumpOutline(tester, fresh);

      await tester.tap(find.text('Tri unique'));
      await tester.pumpAndSettle();

      // Le defaut signale par l'auteur : le selecteur du nombre restait
      // visible, alors qu'un tri unique n'a qu'une liste a thème.
      expect(find.text('Combien de trajets partent d\'ici ?'), findsNothing);
      expect(find.text('2'), findsNothing);
      expect(tripField(0), findsOneWidget);
      expect(tripField(1), findsNothing);
      expect(find.text('Le thème'), findsOneWidget);
    });

    testWidgets('le theme et le reste apparaissent ensemble', (tester) async {
      await defineSingleSort(tester);

      expect(
        find.text('Ce qui se mange → La plage', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Le reste'), findsOneWidget);
    });

    testWidgets('la liste du reste n\'est pas annoncee comme un defaut',
        (tester) async {
      await defineSingleSort(tester);

      // « sans issue » se lisait comme une panne, alors que cette liste est
      // la moitie du dispositif.
      expect(find.text('sans issue'), findsNothing);
      expect(find.text('le reste'), findsOneWidget);
    });

    testWidgets('le lieu annonce sa mecanique', (tester) async {
      await defineSingleSort(tester);

      expect(
        find.text('Tri unique : ce qui est du thème, et tout le reste.'),
        findsOneWidget,
      );
    });

    testWidgets('aucun personnage n\'est invente', (tester) async {
      await defineSingleSort(tester);

      // Le personnage est un ornement : l'outil ne doit pas en poser un dont
      // l'auteur n'a pas voulu.
      expect(find.byIcon(Icons.person_outline), findsNothing);
    });

    testWidgets('sa sortie posee, il n\'offre plus rien a ajouter',
        (tester) async {
      await defineSingleSort(tester);

      // Seul le lieu atteint, a definir, propose encore quelque chose.
      expect(find.text('Ajouter'), findsNothing);
      expect(find.text('Que fait l\'enfant ici ?'), findsOneWidget);
    });
  });

  group('Clore la journée', () {
    testWidgets('« Une fin » clot le lieu, sans rien a remplir',
        (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Le seuil',
      );
      await pumpOutline(tester, fresh);

      await tester.tap(find.text('Une fin'));
      await tester.pumpAndSettle();

      // Du texte, pas de jeu : rien a nommer, et plus rien a proposer.
      expect(
        find.text('Fin de l\'aventure : du texte, pas de jeu.'),
        findsOneWidget,
      );
      expect(find.text('Que fait l\'enfant ici ?'), findsNothing);
      expect(find.text('Cette aventure est jouable.'), findsOneWidget);
    });

    testWidgets('les fins déjà écrites sont proposées', (tester) async {
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('Ajouter').first);
      await tester.pumpAndSettle();

      // Une fin porte un écran, une image et un texte : deux chemins qui
      // aboutissent au même endroit doivent pouvoir partager la même.
      expect(find.text('Un nouveau lieu'), findsOneWidget);

      await tester.tap(find.text('Un nouveau lieu'));
      await tester.pumpAndSettle();
      expect(find.text('Rejoindre « La plage »'), findsWidgets);
      expect(find.text('Rejoindre « Le garage »'), findsWidgets);
    });

    testWidgets('tout lieu deja ecrit peut etre rejoint, sauf celui-ci',
        (tester) async {
      // Revenir en arriere est permis : la boucle sera signalee, a verifier.
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('Ajouter').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Un nouveau lieu'));
      await tester.pumpAndSettle();

      expect(find.text('Rejoindre « Devant la maison »'), findsWidgets);
      expect(find.text('Rejoindre « La gare »'), findsNothing);
    });

    testWidgets('choisir une fin existante remplit le nom du trajet',
        (tester) async {
      await pumpOutline(tester, realAdventure);

      await tester.tap(find.text('Ajouter').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Un nouveau lieu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rejoindre « La plage »').last);
      await tester.pumpAndSettle();

      // Sans quoi « Créer » reste éteint sans qu'on voie pourquoi : le nom
      // reste modifiable, il est seulement proposé.
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller!.text, 'La plage');
    });

    testWidgets('sans fin écrite, rien à choisir', (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Le seuil',
      );
      await pumpOutline(tester, fresh);

      await tester.tap(find.text('Plusieurs listes'));
      await tester.pumpAndSettle();

      // Un choix entre une seule possibilite n'est pas un choix.
      expect(find.text('Un nouveau lieu'), findsNothing);
    });
  });

  group('Les listes de mots', () {
    testWidgets('un trajet neuf dit qu\'il n\'a pas de liste', (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Le seuil',
      );
      await pumpOutline(tester, fresh);
      await addTripFromStart(tester, 'En bus');

      expect(find.text('pas de liste'), findsOneWidget);
    });

    testWidgets('toucher un trajet ouvre sa liste', (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Le seuil',
      );
      await pumpOutline(tester, fresh);
      await addTripFromStart(tester, 'En bus');

      await tester.tap(find.text('pas de liste'));
      await tester.pumpAndSettle();

      expect(find.text('Ce trajet n\'a pas encore de liste de mots.'), findsOneWidget);
    });

    testWidgets('une liste gardee revient sur la carte, a enregistrer',
        (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Le seuil',
      );
      await pumpOutline(tester, fresh, onSave: (_) async => <String>[]);
      await addTripFromStart(tester, 'En bus');

      await tester.tap(find.text('pas de liste'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer une liste'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garder'));
      await tester.pumpAndSettle();

      // La liste existe, vide : sept mots demandes, aucun ecrit.
      expect(find.text('pas de liste'), findsNothing);
      expect(find.text('0/7'), findsOneWidget);
    });

    testWidgets('le contenu livre montre ce que chaque liste offre',
        (tester) async {
      await pumpOutline(tester, realAdventure);

      // Aucun lieu livre ne demande de nombre : chaque liste joue entiere, et
      // la carte dit combien de mots elle met en jeu.
      expect(find.text('pas de liste'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);
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
      expect(find.text('Que fait l\'enfant ici ?'), findsOneWidget);
    });

    testWidgets('elle se construit de proche en proche', (tester) async {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Le seuil',
      );
      await pumpOutline(tester, fresh);

      await tester.tap(find.text('Plusieurs listes'));
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
