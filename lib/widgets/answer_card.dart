import 'package:flutter/material.dart';

import '../theme.dart';

/// Visual state of an answer card after the player taps something.
enum CardState { idle, correct, wrong, revealed }

/// A single tappable answer card.
class AnswerCard extends StatelessWidget {
  const AnswerCard({
    super.key,
    required this.value,
    required this.color,
    required this.state,
    required this.onTap,
  });

  final int value;
  final Color color;
  final CardState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color background = color;
    Widget? badge;
    switch (state) {
      case CardState.idle:
        background = color;
        break;
      case CardState.correct:
        background = AppTheme.correct;
        badge = const Icon(Icons.check_circle, color: Colors.white, size: 28);
        break;
      case CardState.wrong:
        background = AppTheme.incorrect;
        badge = const Icon(Icons.cancel, color: Colors.white, size: 28);
        break;
      case CardState.revealed:
        background = AppTheme.correct.withOpacity(0.85);
        badge = const Icon(Icons.check, color: Colors.white, size: 24);
        break;
    }

    return AnimatedScale(
      scale: state == CardState.idle ? 1.0 : 1.04,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Stack(
            children: [
              Center(
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (badge != null)
                Positioned(top: 6, right: 6, child: badge),
            ],
          ),
        ),
      ),
    );
  }
}
