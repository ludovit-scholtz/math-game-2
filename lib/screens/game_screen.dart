import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../logic/game_controller.dart';
import '../models/background_style.dart';
import '../models/game_config.dart';
import '../models/question.dart';
import '../services/audio_service.dart';
import '../services/coin_service.dart';
import '../theme.dart';
import '../widgets/answer_card.dart';
import 'results_screen.dart';

/// The main gameplay screen: a countdown timer, the current question and six
/// shuffled answer cards.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.config});

  final GameConfig config;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  final AudioService _audio = AudioService();
  final CoinService _coinService = CoinService();

  /// The background style assigned to each of the six button positions.
  List<BackgroundStyle> _positionStyles = List<BackgroundStyle>.from(
    BackgroundStyle.defaults,
  );

  late int _remainingSeconds;
  Timer? _timer;

  late Question _question;
  DateTime _questionStart = DateTime.now();
  int? _selectedAnswer;
  bool _locked = false;
  String _feedback = '';
  bool _feedbackIsNegative = false;

  @override
  void initState() {
    super.initState();
    _controller = GameController(operations: widget.config.operations);
    _remainingSeconds = widget.config.duration.seconds;
    _question = _controller.nextQuestion();
    _questionStart = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    _loadStyles();
  }

  Future<void> _loadStyles() async {
    final wallet = await _coinService.load(widget.config.playerName);
    if (!mounted) return;
    setState(() {
      _positionStyles = [
        for (var i = 0; i < BackgroundStyle.positions; i++)
          BackgroundCatalog.byId(wallet.assignments[i]) ??
              BackgroundStyle.defaults[i],
      ];
    });
  }

  void _onTick(Timer timer) {
    if (!mounted) return;
    setState(() => _remainingSeconds--);
    if (_remainingSeconds <= 0) {
      _endGame();
    }
  }

  Future<void> _onAnswerTapped(int value) async {
    if (_locked) return;
    final strings = context.strings;
    final elapsed =
        DateTime.now().difference(_questionStart).inMilliseconds / 1000.0;
    final result = _controller.submitAnswer(_question, value, elapsed);

    setState(() {
      _locked = true;
      _selectedAnswer = value;
      if (result.correct) {
        final pts = result.pointsAwarded;
        _feedback = pts > 0
            ? strings.niceFeedback(
                pts.toStringAsFixed(pts.truncateToDouble() == pts ? 0 : 1),
              )
            : strings.slowFeedback();
        _feedbackIsNegative = pts <= 0;
      } else {
        _feedback = strings.oopsFeedback(_question.correctAnswer);
        _feedbackIsNegative = true;
      }
    });

    if (result.correct && result.pointsAwarded > 0) {
      unawaited(_audio.playCorrect());
    } else {
      unawaited(_audio.playIncorrect());
    }

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || _remainingSeconds <= 0) return;
    setState(() {
      _question = _controller.nextQuestion();
      _questionStart = DateTime.now();
      _selectedAnswer = null;
      _locked = false;
      _feedback = '';
      _feedbackIsNegative = false;
    });
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    unawaited(_audio.playGameOver());
    if (!mounted) return;
    final score = _controller.score.round();
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          finishedConfig: widget.config,
          finalScore: score,
          correctCount: _controller.correctCount,
          answeredCount: _controller.answeredCount,
        ),
      ),
    );
  }

  CardState _cardState(int value) {
    if (!_locked) return CardState.idle;
    if (value == _question.correctAnswer) {
      return value == _selectedAnswer ? CardState.correct : CardState.revealed;
    }
    if (value == _selectedAnswer) return CardState.wrong;
    return CardState.idle;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.config.duration.seconds;
    final progress = _remainingSeconds / totalSeconds;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final padding = EdgeInsets.all(isLandscape ? 16 : 20);
            final availableWidth = constraints.maxWidth - padding.horizontal;
            final crossAxisCount = isLandscape && availableWidth >= 560 ? 3 : 2;
            final verticalGap = isLandscape ? 20.0 : 36.0;
            final questionFontSize = isLandscape ? 52.0 : 64.0;

            return SingleChildScrollView(
              padding: padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - padding.vertical,
                ),
                child: Column(
                  children: [
                    _TopBar(
                      remainingSeconds: _remainingSeconds,
                      score: _controller.score.round(),
                      progress: progress.clamp(0.0, 1.0),
                      quitTooltip: context.strings.quit,
                      onQuit: () {
                        _timer?.cancel();
                        Navigator.of(context).pop();
                      },
                    ),
                    SizedBox(height: verticalGap),
                    Text(
                      _question.prompt,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: questionFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 28,
                      child: Text(
                        _feedback,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _feedbackIsNegative
                              ? AppTheme.incorrect
                              : AppTheme.correct,
                        ),
                      ),
                    ),
                    SizedBox(height: verticalGap),
                    GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.9,
                      children: [
                        for (var i = 0; i < _question.options.length; i++)
                          AnswerCard(
                            value: _question.options[i],
                            gradient:
                                _positionStyles[i % _positionStyles.length]
                                    .gradient,
                            state: _cardState(_question.options[i]),
                            onTap: _locked
                                ? null
                                : () => _onAnswerTapped(_question.options[i]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.remainingSeconds,
    required this.score,
    required this.progress,
    required this.quitTooltip,
    required this.onQuit,
  });

  final int remainingSeconds;
  final int score;
  final double progress;
  final String quitTooltip;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final minutes = (remainingSeconds ~/ 60).toString();
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onQuit,
              icon: const Icon(Icons.close_rounded),
              tooltip: quitTooltip,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppTheme.secondary),
                const SizedBox(width: 4),
                Text(
                  '$minutes:$seconds',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppTheme.secondary),
                const SizedBox(width: 4),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppTheme.primary.withOpacity(0.15),
          ),
        ),
      ],
    );
  }
}
