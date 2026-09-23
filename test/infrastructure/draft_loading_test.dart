import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/infrastructure/content/content_repository.dart';

import '../support/memory_content.dart';

/// Le jeu refuse une aventure incomplete ; l'outil d'auteur doit l'ouvrir.
///
/// `loadAdventure` echoue des la moindre anomalie, et c'est le bon contrat pour
/// le jeu : une aventure incomplete est injouable, et mieux vaut un message
/// clair au chargement qu'un jeu bloque sans explication devant l'enfant.
///
/// Mais une aventure en cours d'ecriture est incomplete par definition. Avec ce
/// seul chemin, l'outil d'auteur ne pourrait jamais rouvrir ce qu'il vient
/// d'enregistrer.

/// Une aventure a laquelle il manque encore les mots d'une famille.
///
/// Exactement l'etat d'un lieu qu'on vient de creer dans l'outil.
Map<String, String> buildDraftFiles() {
  return <String, String>{
    'index.json': '''
{
  "lexicons": ["lexicon/test.json"],
  "lists": ["lists/test.json"],
  "adventures": [
    { "id": "brouillon", "title": "Brouillon", "file": "adventures/b.json" }
  ]
}''',
    'lexicon/test.json':
        '{ "domain": "test", "words": [ { "text": "un", "syllables": ["un"] } ] }',
    'lists/test.json':
        '{ "domain": "test", "lists": [ { "id": "vide", "name": "Vide", "words": [] } ] }',
    'adventures/b.json': '''
{
  "id": "brouillon",
  "title": "Brouillon",
  "startStageId": "depart",
  "stages": [
    {
      "id": "depart",
      "location": "Depart",
      "families": [
        { "id": "en_bus", "label": "En autocar", "list": "vide",
          "destination": "marche" }
      ]
    }
  ]
}''',
  };
}

ContentRepository buildRepository() {
  return ContentRepository(source: MemoryContentFolder(buildDraftFiles()));
}

void main() {
  group('Charger un brouillon', () {
    test('le jeu refuse l\'aventure incomplete, en disant quoi', () async {
      expect(
        () => buildRepository().loadAdventure('brouillon'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('en_bus'),
          ),
        ),
      );
    });

    test('l\'outil d\'auteur l\'ouvre telle quelle', () async {
      final draft = await buildRepository().loadDraft('brouillon');

      expect(draft.id, 'brouillon');
      expect(draft.stages, hasLength(1));
    });

    test('et retrouve ce qu\'il reste a faire', () async {
      final draft = await buildRepository().loadDraft('brouillon');
      final issues = draft.validate();

      // Une famille sans mots, et une destination annoncee avant son lieu.
      expect(issues, hasLength(2));
      expect(
        issues.every((issue) => issue.severity == IssueSeverity.incomplete),
        isTrue,
        reason: 'Rien n\'est faux ici : tout reste a ecrire.',
      );
    });

    test('un brouillon fautif s\'ouvre aussi, sans quoi on ne pourrait pas '
        'le corriger', () async {
      final files = buildDraftFiles();
      // Le mot « un » se retrouve dans le nom de sa famille : c'est une faute,
      // pas un manque. Elle ne doit pas empecher d'ouvrir le fichier.
      files['lists/test.json'] =
          '{ "domain": "test", "lists": [ { "id": "vide", "name": "Vide", '
          '"words": ["un"] } ] }';
      files['adventures/b.json'] = files['adventures/b.json']!
          .replaceAll('"label": "En autocar"', '"label": "Chiffre un"');

      final draft = await ContentRepository(
        source: MemoryContentFolder(files),
      ).loadDraft('brouillon');

      expect(
        draft.validate().where((i) => i.severity == IssueSeverity.wrong),
        hasLength(1),
      );
    });

    test('une aventure que le sommaire ignore reste introuvable', () async {
      // Tolerer l'incomplet n'est pas tolerer n'importe quoi : un fichier
      // absent du sommaire n'est pas un brouillon, c'est une erreur de nom.
      expect(
        () => buildRepository().loadDraft('inconnue'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
