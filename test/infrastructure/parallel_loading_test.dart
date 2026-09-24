import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/infrastructure/content/content_repository.dart';

import '../support/disk_content.dart';

/// Charger une aventure ne doit pas demander les fichiers un par un.
///
/// Sur un disque, huit lectures en file indienne sont instantanées. Depuis un
/// dépôt distant, dans un navigateur, ce sont huit allers-retours réseau qui
/// s'additionnent : l'ouverture d'une aventure prenait plusieurs secondes, et
/// l'auteur le voyait.
///
/// Les lexiques, les listes, les personnages et le fichier d'aventure sont
/// **indépendants à la lecture** : une liste ne cite le lexique qu'au moment
/// d'être analysée, pas d'être lue.

/// Compte combien de lectures sont en vol **en même temps**.
///
/// Chaque lecture cède la main avant de répondre : si le chargement demandait
/// ses fichiers l'un après l'autre, le maximum resterait à 1.
class ConcurrencyCountingSource implements ContentSource {
  ConcurrencyCountingSource(this.inner);

  final ContentSource inner;

  int inFlight = 0;
  int peak = 0;
  final List<String> requested = <String>[];

  Future<T> _watch<T>(String path, Future<T> Function() read) async {
    requested.add(path);
    inFlight += 1;
    peak = peak > inFlight ? peak : inFlight;
    try {
      // Cède la main : toutes les lectures lancées ensemble se comptent alors
      // ensemble, ce qui est exactement ce qu'on veut mesurer.
      await Future<void>.delayed(Duration.zero);
      return await read();
    } finally {
      inFlight -= 1;
    }
  }

  @override
  Future<String> readFile(String path) => _watch(path, () => inner.readFile(path));

  @override
  Future<Uint8List> readBytes(String path) =>
      _watch(path, () => inner.readBytes(path));
}

void main() {
  late ConcurrencyCountingSource source;
  late ContentRepository repository;

  setUp(() {
    source = ConcurrencyCountingSource(const DiskContentSource());
    repository = ContentRepository(source: source);
  });

  test('les fichiers d\'une aventure se demandent ensemble', () async {
    await repository.loadAdventure('grisbie_plage');

    // Quatre lexiques, trois listes et l'aventure : huit fichiers après le
    // sommaire. Un par un, le sommet resterait à 1.
    expect(source.requested, hasLength(9));
    expect(
      source.peak,
      greaterThan(1),
      reason: 'les lectures doivent partir ensemble, pas en file indienne',
    );
  });

  test('le sommaire vient d\'abord, seul', () async {
    // Il dit **quels** fichiers demander : rien ne peut partir avant lui.
    await repository.loadAdventure('grisbie_plage');

    expect(source.requested.first, 'index.json');
  });

  test('le contenu chargé est le même', () async {
    // Le fond du contrôle : paralléliser ne doit rien changer au résultat.
    final parallel = await repository.loadAdventure('grisbie_plage');
    final reference = await buildDiskRepository().loadAdventure('grisbie_plage');

    expect(parallel.stages.keys, reference.stages.keys);
    expect(
      parallel.findStage('gare')!.families.map((f) => f.label),
      reference.findStage('gare')!.families.map((f) => f.label),
    );
    expect(parallel.opening?.title, reference.opening?.title);
  });

  test('un second chargement ne relit rien d\'inutile', () async {
    await repository.loadAdventure('grisbie_plage');
    final afterFirst = source.requested.length;

    await repository.loadDraft('grisbie_plage');

    // Le sommaire, les lexiques, les listes et les personnages restent en
    // mémoire : seule l'aventure est relue.
    expect(source.requested.length - afterFirst, 1);
  });
}
