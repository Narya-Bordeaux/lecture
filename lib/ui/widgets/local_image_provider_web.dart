import 'package:flutter/widgets.dart';

/// L'image d'un fichier, dans un navigateur — ou plutot : son absence.
///
/// **Un navigateur n'a pas de disque.** Ce qui serait un chemin de fichier
/// ailleurs y est forcement une adresse : le blob d'une image que l'auteur
/// vient de choisir, ou le fichier depose sur un stockage distant.
///
/// Branche choisie a la compilation quand `dart:io` n'existe pas. Voir
/// `content_image.dart`.
ImageProvider localImageProvider(String path) => NetworkImage(path);
