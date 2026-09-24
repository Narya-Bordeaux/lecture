import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/adventure_opening.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';
import 'package:grisbie/ui/pages/narration_page.dart';

/// La page de garde d'une aventure, sur l'ecran de lecture ([NarrationPage]).
///
/// Un seuil que l'on franchit une fois. Le titre de l'aventure sert quand
/// l'ouverture n'en donne pas.
class AdventureOpeningPage extends StatelessWidget {
  const AdventureOpeningPage({
    required this.opening,
    required this.adventureTitle,
    required this.onStart,
    super.key,
  });

  final AdventureOpening opening;

  /// Sert de titre si l'ouverture n'en donne pas.
  final String adventureTitle;

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return NarrationPage(
      title: opening.titleOr(adventureTitle),
      imagePath: opening.imageAsset,
      text: opening.text,
      actionLabel: UiStringsFr.startAdventure,
      onAction: onStart,
    );
  }
}
