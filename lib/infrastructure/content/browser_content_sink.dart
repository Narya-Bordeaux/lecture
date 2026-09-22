import 'package:grisbie/domain/repositories/content_sink.dart';
// La branche est choisie a la compilation : le telechargement n'existe que
// dans un navigateur, et son implementation n'y compile que la.
import 'package:grisbie/infrastructure/content/browser_content_sink_web.dart'
    if (dart.library.io) 'package:grisbie/infrastructure/content/browser_content_sink_io.dart';

/// Le puits qui rend les fichiers par le telechargement du navigateur.
///
/// Voir `browser_content_sink_web.dart` : c'est un depannage, en attendant un
/// depot distant. Chaque fichier descend separement, et se repose a la main
/// dans `assets/content/`.
ContentSink browserContentSink() => createBrowserContentSink();
