import 'dart:io';

import 'package:flutter/widgets.dart';

/// L'image d'un fichier, sur un appareil.
///
/// Branche choisie **a la compilation** quand `dart:io` existe — telephone,
/// bureau, tests. Voir `content_image.dart` pour l'autre.
ImageProvider localImageProvider(String path) => FileImage(File(path));
