import 'package:grisbie/domain/repositories/content_store.dart';
// La branche est choisie a la compilation : l'acces aux dossiers du poste
// n'existe que dans un navigateur, et son implementation n'y compile que la.
import 'package:grisbie/infrastructure/content/browser_content_folder_web.dart'
    if (dart.library.io) 'package:grisbie/infrastructure/content/browser_content_folder_io.dart';

/// Vrai si l'on peut designer un dossier du poste : Chrome ou Edge.
bool canPickContentFolder() => canPickContentFolderImpl();

/// Demande a l'auteur de designer un dossier du poste, lu et ecrit.
/// Rend `null` s'il renonce.
Future<ContentStore?> pickContentFolder() => pickContentFolderImpl();
