import 'package:grisbie/domain/repositories/content_sink.dart';

/// Hors navigateur, il n'y a rien a telecharger.
///
/// Branche choisie a la compilation quand `dart:io` existe. Personne ne devrait
/// l'appeler : l'outil construit le puits de fichiers sur un appareil. Elle
/// echoue donc en le disant, plutot que de ne rien faire en silence.
ContentSink createBrowserContentSink() {
  throw UnsupportedError(
    'Le telechargement par le navigateur n\'existe que sur le web.',
  );
}
