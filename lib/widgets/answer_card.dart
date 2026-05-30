import 'package:flutter/material.dart';

import '../theme.dart';

/// Visual state of an answer card after the player taps something.
enum CardState { idle, correct, wrong, revealed }

/// A single tappable answer card. While idle it shows the player's chosen
/// background [gradient]; after an answer it switches to a solid feedback colour.
class AnswerCard extends StatelessWidget {
  const AnswerCard({
    super.key,
    required this.value,
    required this.gradient,
    required this.state,
    required this.onTap,
  });

  final int value;
  final Gradient gradient;
  final CardState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Gradient? showGradient = gradient;
    Color? solid;
    Widget? badge;
    switch (state) {
      case CardState.idle:
        break;
      case CardState.correct:
        showGradient = null;
        solid = AppTheme.correct;
        badge = const Icon(Icons.check_circle, color: Colors.white, size: 28);
        break;
      case CardState.wrong:
        showGradient = null;
        solid = AppTheme.incorrect;
        badge = const Icon(Icons.cancel, color: Colors.white, size: 28);
        break;
      case CardState.revealed:
        showGradient = null;
        solid = AppTheme.correct.withOpacity(0.85);
        badge = const Icon(Icons.check, color: Colors.white, size: 24);
        break;
    }

    final borderRadius = BorderRadius.circular(AppTheme.buttonRadius);
    return AnimatedScale(
      scale: state == CardState.idle ? 1.0 : 1.04,
      duration: const Duration(milliseconds: 150),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: showGradient,
          color: solid,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
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
      ),
    );
  }
}
