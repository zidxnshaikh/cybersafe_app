import 'package:flutter/material.dart';

class ScamSimulatorScreen extends StatefulWidget {
  const ScamSimulatorScreen({super.key});

  @override
  State<ScamSimulatorScreen> createState() => _ScamSimulatorScreenState();
}

class _ScamSimulatorScreenState extends State<ScamSimulatorScreen> {
  int _scenarioIndex = 0;
  int? _selectedAnswer;

  static const _scenarios = [
    (
      message: 'Your bank account will be blocked today. Reply with the one-time code we just sent to verify your identity.',
      options: ['Send the code to avoid a block', 'Contact the bank using its official app or number'],
      answer: 1,
      explanation: 'Banks should not ask you to share one-time codes. Contact the bank through a trusted channel.',
    ),
    (
      message: 'You have won a prize. Scan this QR code and enter your payment PIN to receive the money.',
      options: ['Scan it and enter the PIN', 'Do not scan it; a PIN authorizes payments'],
      answer: 1,
      explanation: 'A payment PIN authorizes a debit. You do not need to enter one to receive money.',
    ),
    (
      message: 'A delivery fee is due. Use this shortened link and pay within 10 minutes or your parcel will be returned.',
      options: ['Open the link immediately', 'Check delivery status in the retailer or courier app'],
      answer: 1,
      explanation: 'Unexpected urgency and payment links are warning signs. Check directly with the service.',
    ),
  ];

  void _nextScenario() {
    setState(() {
      _scenarioIndex = (_scenarioIndex + 1) % _scenarios.length;
      _selectedAnswer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scenario = _scenarios[_scenarioIndex];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Scam Spotting Practice', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Scenario ${_scenarioIndex + 1} of ${_scenarios.length}',
          style: TextStyle(color: Colors.grey[400])),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(14)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.message_outlined, color: Color(0xFF06B6D4)),
            const SizedBox(width: 12),
            Expanded(child: Text('“${scenario.message}”', style: const TextStyle(height: 1.5))),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('What is the safest response?', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (var i = 0; i < scenario.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: _selectedAnswer == null ? () => setState(() => _selectedAnswer = i) : null,
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(14),
                side: BorderSide(color: _selectedAnswer == i
                    ? (i == scenario.answer ? Colors.greenAccent : Colors.redAccent)
                    : Colors.white24),
              ),
              child: Text(scenario.options[i]),
            ),
          ),
        if (_selectedAnswer != null) ...[
          const SizedBox(height: 8),
          Text(_selectedAnswer == scenario.answer ? 'Correct choice' : 'Not the safest choice',
            style: TextStyle(fontWeight: FontWeight.bold,
              color: _selectedAnswer == scenario.answer ? Colors.greenAccent : Colors.orangeAccent)),
          const SizedBox(height: 6),
          Text(scenario.explanation),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _nextScenario,
            icon: const Icon(Icons.arrow_forward), label: const Text('Next scenario')),
        ],
      ],
    );
  }
}