import 'dart:math';

import '../models/operation_type.dart';
import '../models/question.dart';
import 'question_generator.dart';
import 'scoring.dart';

/// The outcome of answering a single question.
class AnswerResult {
  AnswerResult({required this.correct, required this.pointsAwarded});

  final bool correct;
  final double pointsAwarded;
}

/// Drives a single game session: it produces questions, tracks the running
/// score and re-queues any question the player gets wrong so it comes back a
/// few questions later (spaced repetition).
class GameController {
  GameController({
    required this.operations,
    QuestionGenerator? generator,
    this.reaskAfter = 3,
  }) : _generator = generator ?? QuestionGenerator(random: Random());

  final Set<OperationType> operations;
  final QuestionGenerator _generator;

  /// How many fresh questions appear before a missed question returns.
  final int reaskAfter;

  final List<_PendingReask> _pending = <_PendingReask>[];

  double _score = 0;
  int _answered = 0;
  int _correct = 0;

  double get score => _score;
  int get answeredCount => _answered;
  int get correctCount => _correct;

  /// Returns the next question to show, preferring a previously missed question
  /// whose cooldown has elapsed.
  Question nextQuestion() {
    for (final pending in _pending) {
      pending.countdown--;
    }
    final dueIndex = _pending.indexWhere((p) => p.countdown <= 0);
    if (dueIndex != -1) {
      return _pending.removeAt(dueIndex).question;
    }
    return _generator.generate(operations);
  }

  /// Records the player's answer, updates the score and schedules a re-ask on a
  /// wrong answer. [seconds] is how long the player took to respond.
  AnswerResult submitAnswer(
    Question question,
    int chosenAnswer,
    double seconds,
  ) {
    _answered++;
    final correct = chosenAnswer == question.correctAnswer;
    double points;
    if (correct) {
      _correct++;
      points = Scoring.pointsForCorrect(seconds);
    } else {
      points = Scoring.wrongPenalty;
      _scheduleReask(question);
    }
    _score += points;
    return AnswerResult(correct: correct, pointsAwarded: points);
  }

  void _scheduleReask(Question question) {
    _pending
      ..removeWhere((p) => p.question == question)
      ..add(_PendingReask(question, reaskAfter));
  }
}

class _PendingReask {
  _PendingReask(this.question, this.countdown);

  final Question question;
  int countdown;
}
