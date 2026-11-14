import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../logic/parental_gate.dart';

/// Asks a question only a grown-up can answer. Resolves to `true` when it was
/// answered correctly. A wrong answer shows a fresh question, so the answer
/// cannot simply be guessed one value after another.
Future<bool> showParentalGate(
  BuildContext context, {
  Random? random,
  DateTime Function() now = DateTime.now,
}) async {
  // After too many wrong answers the gate stays shut for a while, so the
  // answer cannot be found by pressing Check over and over.
  final until = ParentalGateLockout.until;
  if (until != null && now().isBefore(until)) return false;
  final passed = await showDialog<bool>(
    context: context,
    builder: (_) => ParentalGateDialog(random: random),
  );
  return passed ?? false;
}

/// Remembers, for the running app, that the gate was locked after repeated
/// wrong answers.
class ParentalGateLockout {
  ParentalGateLockout._();

  /// Wrong answers in a row after which the gate closes and locks.
  static const int maxAttempts = 5;
  static const Duration duration = Duration(seconds: 30);

  static DateTime? until;

  /// Wrong answers since the last correct one. Counted across openings of the
  /// dialog, so closing and reopening it does not reset the limit.
  static int failures = 0;

  /// Records a wrong answer; returns true when this one locked the gate.
  static bool recordFailure([DateTime? now]) {
    failures++;
    if (failures < maxAttempts) return false;
    failures = 0;
    until = (now ?? DateTime.now()).add(duration);
    return true;
  }

  static void reset() {
    until = null;
    failures = 0;
  }
}

class ParentalGateDialog extends StatefulWidget {
  const ParentalGateDialog({super.key, this.random});

  /// Injectable for tests.
  final Random? random;

  @override
  State<ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<ParentalGateDialog> {
  final TextEditingController _controller = TextEditingController();
  late ParentalChallenge _challenge;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _challenge = ParentalChallenge.generate(widget.random);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_challenge.check(_controller.text)) {
      ParentalGateLockout.failures = 0;
      Navigator.of(context).pop(true);
      return;
    }
    if (ParentalGateLockout.recordFailure()) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      _wrong = true;
      _challenge = ParentalChallenge.generate(widget.random);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AlertDialog(
      title: Text(strings.parentalGateTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.parentalGateQuestion),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _challenge.expression,
                key: const ValueKey('parental-expression'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.parentalGateHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('parental-answer'),
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 3,
              decoration: InputDecoration(
                labelText: strings.parentalGateAnswer,
                errorText: _wrong ? strings.parentalGateWrong : null,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.cancel),
        ),
        ElevatedButton(
          key: const ValueKey('parental-check'),
          onPressed: _submit,
          child: Text(strings.check),
        ),
      ],
    );
  }
}
