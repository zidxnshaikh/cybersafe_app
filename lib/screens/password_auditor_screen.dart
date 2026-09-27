import 'package:flutter/material.dart';

class PasswordAuditorScreen extends StatefulWidget {
  const PasswordAuditorScreen({super.key});

  @override
  State<PasswordAuditorScreen> createState() => _PasswordAuditorScreenState();
}

class _PasswordAuditorScreenState extends State<PasswordAuditorScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final password = _controller.text;
    final checks = <(String, bool)>[
      ('At least 12 characters', password.length >= 12),
      ('Uppercase and lowercase letters', RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(password)),
      ('At least one number', RegExp(r'\d').hasMatch(password)),
      ('At least one symbol', RegExp(r'[^A-Za-z0-9]').hasMatch(password)),
    ];
    final score = checks.where((check) => check.$2).length;
    final color = score <= 1 ? Colors.redAccent : score <= 3 ? Colors.orangeAccent : Colors.greenAccent;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Password Auditor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Check password composition locally. Nothing is sent or stored.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          obscureText: _obscure,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Enter a password to check',
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (password.isNotEmpty) ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(score == 4 ? 'Good composition' : 'Needs improvement',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            Text('$score/4', style: TextStyle(color: color)),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: score / 4, color: color, minHeight: 6),
          const SizedBox(height: 16),
        ],
        ...checks.map((check) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(check.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
            color: check.$2 ? Colors.greenAccent : Colors.grey),
          title: Text(check.$1),
        )),
        const SizedBox(height: 8),
        const Text('Use a unique passphrase for every account. This check does not test whether a password has appeared in a data breach.',
          style: TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}