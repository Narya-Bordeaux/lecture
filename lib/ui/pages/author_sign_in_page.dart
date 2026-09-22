import 'package:flutter/material.dart';
import 'package:grisbie/domain/repositories/author_account.dart';

/// Se connecter au depot distant.
///
/// Par e-mail et mot de passe : l'usage est solo, un seul compte cree a la
/// main dans la console, et la regle du bucket nomme son identifiant.
///
/// L'ecran ne sait rien du fournisseur — il montre un etat et transmet deux
/// gestes, a travers [AuthorAccount].
class AuthorSignInPage extends StatefulWidget {
  const AuthorSignInPage({required this.account, super.key});

  final AuthorAccount account;

  @override
  State<AuthorSignInPage> createState() => _AuthorSignInPageState();
}

class _AuthorSignInPageState extends State<AuthorSignInPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  /// Ce qui a echoue, dit en clair. Nul tant que rien n'a echoue.
  String? _failure;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_busy &&
      _email.text.trim().isNotEmpty &&
      _password.text.isNotEmpty;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _failure = null;
    });

    final failure = await widget.account.signIn(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;

    setState(() {
      _busy = false;
      _failure = failure;
    });
    if (failure == null) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dépôt distant')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Le compte de l\'auteur, créé à la main dans la console. Une fois '
            'connecté, « Enregistrer » dépose le contenu sur le dépôt au lieu '
            'de cet appareil.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('password'),
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _canSubmit ? _submit() : null,
          ),
          if (_failure != null) ...<Widget>[
            const SizedBox(height: 16),
            // Un echec muet laisserait croire a une panne de reseau, et on
            // recommencerait le meme mot de passe.
            Text(
              _failure!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: Text(_busy ? 'Connexion…' : 'Se connecter'),
          ),
        ],
      ),
    );
  }
}
