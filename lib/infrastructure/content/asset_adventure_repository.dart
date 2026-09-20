import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:reading_game/domain/models/adventure.dart';
import 'package:reading_game/domain/repositories/adventure_repository.dart';

/// Charge les aventures depuis les fichiers JSON embarques dans l'application.
class AssetAdventureRepository implements AdventureRepository {
  const AssetAdventureRepository({this.bundle});

  static const String _basePath = 'assets/content/adventures';

  /// Injectable pour charger un contenu de substitution dans les tests, sans
  /// dependre des assets reellement embarques dans l'application.
  final AssetBundle? bundle;

  AssetBundle get _assets => bundle ?? rootBundle;

  @override
  Future<Adventure> loadAdventure(String adventureId) async {
    final path = '$_basePath/$adventureId.json';
    final raw = await _assets.loadString(path);
    final adventure = Adventure.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    // Un contenu incoherent produirait un jeu bloque sans message : mieux vaut
    // echouer ici, avec la liste des problemes.
    final issues = adventure.validate();
    if (issues.isNotEmpty) {
      throw FormatException(
        'Contenu invalide dans "$path" :\n- ${issues.join('\n- ')}',
      );
    }

    return adventure;
  }
}
