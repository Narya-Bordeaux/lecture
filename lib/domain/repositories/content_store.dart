import 'package:grisbie/domain/repositories/content_sink.dart';
import 'package:grisbie/domain/repositories/content_source.dart';

/// Un dossier de contenu qui se lit **et** s'ecrit, avec l'arborescence
/// d'`assets/content/`.
///
/// C'est ce qu'il faut pour completer un contenu existant plutot que de
/// l'ecraser : lire ses listes et ses lexiques, puis y reecrire ce qui change,
/// la ou il vit. Le dossier du depot choisi dans le navigateur en est un, le
/// depot distant aussi.
abstract interface class ContentStore implements ContentSource, ContentSink {}
