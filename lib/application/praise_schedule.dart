import 'dart:math';

/// Ce qui salue un mot bien place : une tete de Grisbie, et parfois un mot.
class Praise {
  const Praise({required this.head, this.comment});

  /// La tete qui parait, telle que l'appelant l'a fournie.
  final String head;

  /// Le mot d'encouragement de la bulle. Nul, la tete parait seule.
  final String? comment;

  @override
  String toString() => 'Praise($head, $comment)';
}

/// Decide de la petite recompense qui suit chaque mot bien place.
///
/// **La tete a chaque fois, le mot de temps en temps** (decision de
/// l'auteur) : la tete de Grisbie dit « oui » en un clin d'oeil, et un
/// commentaire (« Super ! ») vient tous les deux ou trois mots. L'ecart est
/// tire au hasard apres chaque commentaire : l'enfant ne peut pas le prevoir,
/// et n'attend jamais plus de trois mots.
///
/// **Une boite pleine a son « Bravo ! »**, la grande fenetre : la tete ne
/// parait pas, et le compte repart de zero, pour qu'un commentaire ne tombe
/// pas juste apres.
///
/// Les tetes alternent ; un mot n'est jamais repete deux fois de suite. Le
/// compte appartient a un lieu : un lieu neuf, un calendrier neuf.
///
/// Dart pur : les tetes et les mots sont de simples chaines, que l'interface
/// traduit en images et en textes.
class PraiseSchedule {
  PraiseSchedule({
    required List<String> heads,
    required List<String> comments,
    Random? random,
  })  : _heads = List<String>.unmodifiable(heads),
        _comments = List<String>.unmodifiable(comments),
        _random = random ?? Random() {
    if (_heads.isEmpty) throw ArgumentError.value(heads, 'heads', 'vide');
    if (_comments.isEmpty) {
      throw ArgumentError.value(comments, 'comments', 'vide');
    }
    _untilComment = _drawGap();
  }

  /// L'ecart entre deux commentaires, bornes compris.
  static const int shortestGap = 2;
  static const int longestGap = 3;

  final List<String> _heads;
  final List<String> _comments;
  final Random _random;

  /// La prochaine tete, par rotation.
  int _nextHead = 0;

  /// Le dernier mot dit, pour ne pas le redire aussitot.
  int? _lastComment;

  /// Combien de bons placements avant le prochain commentaire, celui-ci
  /// compris.
  late int _untilComment;

  /// La recompense du bon placement qui vient d'avoir lieu.
  ///
  /// [boxCelebrated] vrai quand ce placement remplit une boite qui ouvre la
  /// grande fenetre : rien ne parait alors, et le compte repart de zero.
  Praise? next({required bool boxCelebrated}) {
    if (boxCelebrated) {
      _untilComment = _drawGap();
      return null;
    }

    final head = _heads[_nextHead];
    _nextHead = (_nextHead + 1) % _heads.length;

    _untilComment -= 1;
    if (_untilComment > 0) return Praise(head: head);

    _untilComment = _drawGap();
    return Praise(head: head, comment: _comments[_drawComment()]);
  }

  int _drawGap() =>
      shortestGap + _random.nextInt(longestGap - shortestGap + 1);

  /// Un mot au hasard, jamais celui d'avant quand il y en a d'autres.
  int _drawComment() {
    final last = _lastComment;
    int index;
    if (last == null || _comments.length == 1) {
      index = _random.nextInt(_comments.length);
    } else {
      // Tire parmi les autres, puis saute l'ancien.
      index = _random.nextInt(_comments.length - 1);
      if (index >= last) index += 1;
    }
    _lastComment = index;
    return index;
  }
}
