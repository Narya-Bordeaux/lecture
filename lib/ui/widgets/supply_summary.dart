import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/stage.dart';

/// Ce qu'une liste offre dans un lieu : en reste-t-il assez pour jouer ?
///
/// La question que l'auteur a posee pour chaque carte : une fois retires les
/// mots communs a une ou plusieurs autres listes du lieu, y a-t-il encore
/// assez de mots ? Le calcul est dans le domaine (`Stage.supplyOf`) ; ce
/// widget ne fait que le dire, en long sur l'ecran de liste, en court sur la
/// carte du lieu.
class SupplySummary extends StatelessWidget {
  const SupplySummary({required this.supply, this.compact = false, super.key});

  final FamilySupply supply;

  /// Vrai sur la carte du lieu, ou la place manque : « 7/7 ».
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enough = supply.isEnough;
    final color = enough
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.error;
    final icon = enough
        ? Icons.check_circle_outline
        : Icons.warning_amber_outlined;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: color);

    if (compact) {
      final required = supply.required;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            required == null
                ? '${supply.available}'
                : '${supply.available}/$required',
            style: style,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(describe(supply), style: style)),
      ],
    );
  }

  /// La phrase entiere : « 9 mots, dont 2 communs avec les autres listes du
  /// lieu : 7 jouables, il en faut 7. »
  static String describe(FamilySupply supply) {
    final buffer = StringBuffer(
      '${supply.total} mot${supply.total > 1 ? 's' : ''}',
    );
    if (supply.shared > 0) {
      buffer.write(
        ', dont ${supply.shared} commun${supply.shared > 1 ? 's' : ''} '
        'avec les autres listes du lieu',
      );
    }
    buffer.write(
      ' : ${supply.available} jouable${supply.available > 1 ? 's' : ''}',
    );
    final required = supply.required;
    if (required != null) {
      buffer.write(', il en faut $required');
    }
    buffer.write('.');
    return buffer.toString();
  }
}
