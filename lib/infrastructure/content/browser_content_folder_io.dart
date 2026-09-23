import 'package:grisbie/domain/repositories/content_store.dart';

/// Hors navigateur, aucun dossier ne se designe ainsi.
bool canPickContentFolderImpl() => false;

Future<ContentStore?> pickContentFolderImpl() {
  throw UnsupportedError(
    'Designer un dossier du poste n\'existe que dans un navigateur.',
  );
}
