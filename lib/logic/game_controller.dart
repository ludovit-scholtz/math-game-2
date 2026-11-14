import 'dart:math';

import '../models/operation_type.dart';
import '../models/practice_settings.dart';
import '../models/question.dart';
import 'gems.dart';
import 'question_generator.dart';
import 'scoring.dart';

/// The outcome of answering a single question.
class AnswerResult {
  AnswerResult({
    required this.correct,
    required this.pointsAwarded,
    this.gemEarned = false,
    this.streak = 0,
  });

  final bool correct;
  final double pointsAwarded;

  /// True when this answer completed a streak of [Gems.streakLength].
  final bool gemEarned;

  /// Correct answers in a row after this answer (0 after a gem or a miss).
  final int streak;
}

/// Drives a single game session: it produces questions, tracks the running
/// score and re-queues any question the player gets wrong so it comes back a
/// few questions later (spaced repetition). Every [Gems.streakLength] correct
/// answers in a row earn a gem; a wrong answer resets the streak.
class GameController {
  GameController({
    required this.operations,
    this.drills = const <Drill>{},
    PracticeSettings? settings,
    QuestionGenerator? generator,
    this.reaskAfter = 3,
  })  : settings = settings ?? PracticeSettings.defaults(),
        _generator = generator ?? QuestionGenerator(random: Random());

  /// Most distinct missed prompts remembered for the parental history.
  static const int maxMissedPrompts = 20;

  final Set<OperationType> operations;
  final Set<Drill> drills;
  final PracticeSettings settings;
  final QuestionGenerator _generator;

  /// How many [nextQuestion] calls after a miss the missed question returns
  /// on (with the default 3, two fresh questions appear in between).
  final int reaskAfter;

  final List<_PendingReask> _pending = <_PendingReask>[];
  final List<String> _missedPrompts = <String>[];

  double _score = 0;
  int _answered = 0;
  int _correct = 0;
  int _streak = 0; // towards the next gem, resets when a gem is earned
  int _run = 0; // correct answers in a row, resets only on a wrong answer
  int _bestStreak = 0;
  int _gems = 0;
  double _totalSeconds = 0;

  double get score => _score;
  int get answeredCount => _answered;
  int get correctCount => _correct;

  /// Correct answers in a row towards the next gem (back to 0 after a gem).
  int get streak => _streak;

  /// The longest run of correct answers in a row during this game.
  int get bestStreak => _bestStreak;
  int get gemsEarned => _gems;

  /// Average time to answer, in milliseconds (0 before the first answer).
  int get averageAnswerMillis =>
      _answered == 0 ? 0 : (_totalSeconds * 1000 / _answered).round();

  /// Distinct prompts answered wrongly, oldest first (capped).
  List<String> get missedPrompts => List.unmodifiable(_missedPrompts);

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
    return _generator.generate(
      operations,
      drills: drills,
      settings: settings,
    );
  }

  /// Records the player's answer, updates the score and schedules a re-ask on a
  /// wrong answer. [seconds] is how long the player took to respond.
  AnswerResult submitAnswer(
    Question question,
    int chosenAnswer,
    double seconds,
  ) {
    _answered++;
    _totalSeconds += seconds;
    final correct = chosenAnswer == question.correctAnswer;
    double points;
    var gemEarned = false;
    if (correct) {
      _correct++;
      points = Scoring.pointsForCorrect(seconds);
      // A slow answer is still a correct one, so it keeps the streak alive.
      _streak++;
      _run++;
      if (_run > _bestStreak) _bestStreak = _run;
      if (_streak >= Gems.streakLength) {
        _gems++;
        _streak = 0;
        gemEarned = true;
      }
    } else {
      points = Scoring.wrongPenalty;
      _streak = 0;
      _run = 0;
      _scheduleReask(question);
      _rememberMiss(question.prompt);
    }
    _score += points;
    return AnswerResult(
      correct: correct,
      pointsAwarded: points,
      gemEarned: gemEarned,
      streak: _streak,
    );
  }

  void _rememberMiss(String prompt) {
    if (_missedPrompts.contains(prompt) ||
        _missedPrompts.length >= maxMissedPrompts) {
      return;
    }
    _missedPrompts.add(prompt);
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
