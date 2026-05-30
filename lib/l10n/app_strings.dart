import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../models/game_config.dart';
import '../models/operation_type.dart';

class AppStrings {
  AppStrings(Locale locale)
      : _languageCode = _localizedValues.containsKey(locale.languageCode)
            ? locale.languageCode
            : 'en';

  final String _languageCode;

  static const supportedLocales = [
    Locale('en'),
    Locale('sk'),
    Locale('cs'),
    Locale('ru'),
    Locale('de'),
    Locale('zh'),
  ];

  static const localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context));

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'Math Master',
      'homeSubtitle':
          'Practise +, −, × and ÷ under 100 and beat your best score!',
      'yourName': 'Your name',
      'enterYourName': 'Enter your name',
      'challengeLength': 'Challenge length',
      'operationsToPractise': 'Operations to practise',
      'start': 'Start',
      'leaderboard': 'Leaderboard',
      'howScoringWorks': 'How scoring works',
      'scoreFast': '⚡ Answer in under 1 second: 3 points',
      'scoreMedium': '⏱️ Between 1 and 10 seconds: faster = more points',
      'scoreSlow': '🐢 Slower than 10 seconds or wrong: −1 point',
      'scoreRepeat': '🔁 Missed questions come back so you can master them',
      'player': 'Player',
      'quit': 'Quit',
      'nice': 'Nice! +{points}',
      'slow': 'Correct, but too slow! −1',
      'oops': 'Oops! The answer was {answer}',
      'gameOver': 'Game Over',
      'noScoresYet': 'No scores yet. Be the first!',
      'home': 'Home',
      'playAgain': 'Play again',
      'greatJob': '🎉 Great job!',
      'score': 'Score: {score}',
      'correctAccuracy':
          'Correct: {correct} / {answered}  •  Accuracy: {accuracy}%',
      'choosePlayer': 'Choose player',
      'noPlayersYet': 'No players yet. Add one below.',
      'newPlayer': 'New player',
      'addPlayer': 'Add player',
      'changePlayer': 'Change player',
      'language': 'Language',
      'history': 'History',
      'faults': 'Faults',
      'gamesPlayed': 'Games played',
      'bestScore': 'Best score',
      'noHistoryYet': 'No games played yet.',
      'statistics': 'Statistics',
      'tapToPlay': 'Tap a name to play as that player.',
      'playAs': 'Playing as',
      'duration1': '1 min',
      'duration2': '2 min',
      'duration5': '5 min',
      'addition': 'Add',
      'subtraction': 'Subtract',
      'multiplication': 'Multiply',
      'division': 'Divide',
    },
    'sk': {
      'appName': 'Math Master',
      'homeSubtitle':
          'Precvičuj +, −, × a ÷ do 100 a prekonaj svoje maximum!',
      'yourName': 'Tvoje meno',
      'enterYourName': 'Zadaj svoje meno',
      'challengeLength': 'Dĺžka hry',
      'operationsToPractise': 'Operácie na precvičovanie',
      'start': 'Štart',
      'leaderboard': 'Rebríček',
      'howScoringWorks': 'Ako funguje bodovanie',
      'scoreFast': '⚡ Odpoveď do 1 sekundy: 3 body',
      'scoreMedium': '⏱️ Medzi 1 a 10 sekundami: rýchlejšie = viac bodov',
      'scoreSlow': '🐢 Pomalšie než 10 sekúnd alebo nesprávne: −1 bod',
      'scoreRepeat': '🔁 Zmeškané príklady sa vrátia, aby si ich zvládol',
      'player': 'Hráč',
      'quit': 'Ukončiť',
      'nice': 'Skvelé! +{points}',
      'slow': 'Správne, ale príliš pomaly! −1',
      'oops': 'Ups! Správna odpoveď bola {answer}',
      'gameOver': 'Koniec hry',
      'noScoresYet': 'Zatiaľ žiadne skóre. Buď prvý!',
      'home': 'Domov',
      'playAgain': 'Hrať znova',
      'greatJob': '🎉 Skvelá práca!',
      'score': 'Skóre: {score}',
      'correctAccuracy':
          'Správne: {correct} / {answered}  •  Presnosť: {accuracy}%',
      'choosePlayer': 'Vyber hráča',
      'noPlayersYet': 'Zatiaľ žiadni hráči. Pridaj jedného nižšie.',
      'newPlayer': 'Nový hráč',
      'addPlayer': 'Pridať hráča',
      'changePlayer': 'Zmeniť hráča',
      'language': 'Jazyk',
      'history': 'História',
      'faults': 'Chyby',
      'gamesPlayed': 'Odohraté hry',
      'bestScore': 'Najlepšie skóre',
      'noHistoryYet': 'Zatiaľ žiadne odohraté hry.',
      'statistics': 'Štatistiky',
      'tapToPlay': 'Klikni na meno a hraj ako tento hráč.',
      'playAs': 'Hráš ako',
      'duration1': '1 min',
      'duration2': '2 min',
      'duration5': '5 min',
      'addition': 'Sčítanie',
      'subtraction': 'Odčítanie',
      'multiplication': 'Násobenie',
      'division': 'Delenie',
    },
    'cs': {
      'appName': 'Math Master',
      'homeSubtitle':
          'Procvičuj +, −, × a ÷ do 100 a překonej své nejlepší skóre!',
      'yourName': 'Tvé jméno',
      'enterYourName': 'Zadej své jméno',
      'challengeLength': 'Délka hry',
      'operationsToPractise': 'Operace k procvičení',
      'start': 'Start',
      'leaderboard': 'Žebříček',
      'howScoringWorks': 'Jak funguje bodování',
      'scoreFast': '⚡ Odpověď do 1 sekundy: 3 body',
      'scoreMedium': '⏱️ Mezi 1 a 10 sekundami: rychleji = více bodů',
      'scoreSlow': '🐢 Pomaleji než 10 sekund nebo špatně: −1 bod',
      'scoreRepeat': '🔁 Zmeškané příklady se vrátí, abys je zvládl',
      'player': 'Hráč',
      'quit': 'Ukončit',
      'nice': 'Skvělé! +{points}',
      'slow': 'Správně, ale příliš pomalu! −1',
      'oops': 'Jejda! Správná odpověď byla {answer}',
      'gameOver': 'Konec hry',
      'noScoresYet': 'Zatím žádné skóre. Buď první!',
      'home': 'Domů',
      'playAgain': 'Hrát znovu',
      'greatJob': '🎉 Skvělá práce!',
      'score': 'Skóre: {score}',
      'correctAccuracy':
          'Správně: {correct} / {answered}  •  Přesnost: {accuracy}%',
      'choosePlayer': 'Vyber hráče',
      'noPlayersYet': 'Zatím žádní hráči. Přidej jednoho níže.',
      'newPlayer': 'Nový hráč',
      'addPlayer': 'Přidat hráče',
      'changePlayer': 'Změnit hráče',
      'language': 'Jazyk',
      'history': 'Historie',
      'faults': 'Chyby',
      'gamesPlayed': 'Odehrané hry',
      'bestScore': 'Nejlepší skóre',
      'noHistoryYet': 'Zatím žádné odehrané hry.',
      'statistics': 'Statistiky',
      'tapToPlay': 'Klikni na jméno a hraj jako tento hráč.',
      'playAs': 'Hraješ jako',
      'duration1': '1 min',
      'duration2': '2 min',
      'duration5': '5 min',
      'addition': 'Sčítání',
      'subtraction': 'Odčítání',
      'multiplication': 'Násobení',
      'division': 'Dělení',
    },
    'ru': {
      'appName': 'Math Master',
      'homeSubtitle':
          'Тренируй +, −, × и ÷ до 100 и побей свой лучший результат!',
      'yourName': 'Твоё имя',
      'enterYourName': 'Введите своё имя',
      'challengeLength': 'Длительность игры',
      'operationsToPractise': 'Операции для тренировки',
      'start': 'Старт',
      'leaderboard': 'Таблица лидеров',
      'howScoringWorks': 'Как начисляются очки',
      'scoreFast': '⚡ Ответ меньше чем за 1 секунду: 3 очка',
      'scoreMedium': '⏱️ От 1 до 10 секунд: быстрее = больше очков',
      'scoreSlow': '🐢 Медленнее 10 секунд или ошибка: −1 очко',
      'scoreRepeat': '🔁 Пропущенные задания вернутся, чтобы ты их освоил',
      'player': 'Игрок',
      'quit': 'Выйти',
      'nice': 'Отлично! +{points}',
      'slow': 'Верно, но слишком медленно! −1',
      'oops': 'Ой! Правильный ответ: {answer}',
      'gameOver': 'Игра окончена',
      'noScoresYet': 'Пока нет результатов. Будь первым!',
      'home': 'Главная',
      'playAgain': 'Сыграть ещё',
      'greatJob': '🎉 Отличная работа!',
      'score': 'Счёт: {score}',
      'correctAccuracy':
          'Верно: {correct} / {answered}  •  Точность: {accuracy}%',
      'choosePlayer': 'Выбери игрока',
      'noPlayersYet': 'Пока нет игроков. Добавь нового ниже.',
      'newPlayer': 'Новый игрок',
      'addPlayer': 'Добавить игрока',
      'changePlayer': 'Сменить игрока',
      'language': 'Язык',
      'history': 'История',
      'faults': 'Ошибки',
      'gamesPlayed': 'Сыграно игр',
      'bestScore': 'Лучший счёт',
      'noHistoryYet': 'Пока нет сыгранных игр.',
      'statistics': 'Статистика',
      'tapToPlay': 'Нажми на имя, чтобы играть за этого игрока.',
      'playAs': 'Играешь как',
      'duration1': '1 мин',
      'duration2': '2 мин',
      'duration5': '5 мин',
      'addition': 'Сложение',
      'subtraction': 'Вычитание',
      'multiplication': 'Умножение',
      'division': 'Деление',
    },
    'de': {
      'appName': 'Math Master',
      'homeSubtitle':
          'Übe +, −, × und ÷ unter 100 und knacke deinen Bestwert!',
      'yourName': 'Dein Name',
      'enterYourName': 'Gib deinen Namen ein',
      'challengeLength': 'Spieldauer',
      'operationsToPractise': 'Zu übende Rechenarten',
      'start': 'Starten',
      'leaderboard': 'Bestenliste',
      'howScoringWorks': 'So funktioniert die Wertung',
      'scoreFast': '⚡ Antwort in unter 1 Sekunde: 3 Punkte',
      'scoreMedium': '⏱️ Zwischen 1 und 10 Sekunden: schneller = mehr Punkte',
      'scoreSlow': '🐢 Langsamer als 10 Sekunden oder falsch: −1 Punkt',
      'scoreRepeat':
          '🔁 Verpasste Aufgaben kommen zurück, bis du sie beherrschst',
      'player': 'Spieler',
      'quit': 'Beenden',
      'nice': 'Super! +{points}',
      'slow': 'Richtig, aber zu langsam! −1',
      'oops': 'Ups! Die richtige Antwort war {answer}',
      'gameOver': 'Spiel vorbei',
      'noScoresYet': 'Noch keine Punkte. Sei der Erste!',
      'home': 'Startseite',
      'playAgain': 'Nochmal spielen',
      'greatJob': '🎉 Tolle Leistung!',
      'score': 'Punktzahl: {score}',
      'correctAccuracy':
          'Richtig: {correct} / {answered}  •  Genauigkeit: {accuracy}%',
      'choosePlayer': 'Spieler wählen',
      'noPlayersYet': 'Noch keine Spieler. Füge unten einen hinzu.',
      'newPlayer': 'Neuer Spieler',
      'addPlayer': 'Spieler hinzufügen',
      'changePlayer': 'Spieler wechseln',
      'language': 'Sprache',
      'history': 'Verlauf',
      'faults': 'Fehler',
      'gamesPlayed': 'Gespielte Spiele',
      'bestScore': 'Bestwert',
      'noHistoryYet': 'Noch keine Spiele gespielt.',
      'statistics': 'Statistik',
      'tapToPlay': 'Tippe auf einen Namen, um als dieser Spieler zu spielen.',
      'playAs': 'Du spielst als',
      'duration1': '1 Min',
      'duration2': '2 Min',
      'duration5': '5 Min',
      'addition': 'Addieren',
      'subtraction': 'Subtrahieren',
      'multiplication': 'Multiplizieren',
      'division': 'Dividieren',
    },
    'zh': {
      'appName': 'Math Master',
      'homeSubtitle': '练习 100 以内的 +、−、× 和 ÷，刷新你的最佳成绩！',
      'yourName': '你的名字',
      'enterYourName': '输入你的名字',
      'challengeLength': '挑战时长',
      'operationsToPractise': '练习的运算',
      'start': '开始',
      'leaderboard': '排行榜',
      'howScoringWorks': '计分规则',
      'scoreFast': '⚡ 1 秒内回答：3 分',
      'scoreMedium': '⏱️ 1 到 10 秒之间：越快分越高',
      'scoreSlow': '🐢 超过 10 秒或答错：−1 分',
      'scoreRepeat': '🔁 错过的题目会再次出现，帮助你掌握它们',
      'player': '玩家',
      'quit': '退出',
      'nice': '太棒了！+{points}',
      'slow': '答对了，但太慢了！−1',
      'oops': '哎呀！正确答案是 {answer}',
      'gameOver': '游戏结束',
      'noScoresYet': '还没有成绩，快来成为第一名！',
      'home': '首页',
      'playAgain': '再玩一次',
      'greatJob': '🎉 干得漂亮！',
      'score': '得分：{score}',
      'correctAccuracy': '答对：{correct} / {answered}  •  正确率：{accuracy}%',
      'choosePlayer': '选择玩家',
      'noPlayersYet': '还没有玩家，请在下方添加。',
      'newPlayer': '新玩家',
      'addPlayer': '添加玩家',
      'changePlayer': '更换玩家',
      'language': '语言',
      'history': '历史',
      'faults': '错误',
      'gamesPlayed': '已玩游戏',
      'bestScore': '最高分',
      'noHistoryYet': '还没有玩过游戏。',
      'statistics': '统计',
      'tapToPlay': '点击名字即可以该玩家身份开始游戏。',
      'playAs': '当前玩家',
      'duration1': '1 分钟',
      'duration2': '2 分钟',
      'duration5': '5 分钟',
      'addition': '加法',
      'subtraction': '减法',
      'multiplication': '乘法',
      'division': '除法',
    },
  };

  Map<String, String> get _strings => _localizedValues[_languageCode]!;

  String get appName => _text('appName');
  String get homeSubtitle => _text('homeSubtitle');
  String get yourName => _text('yourName');
  String get enterYourName => _text('enterYourName');
  String get challengeLength => _text('challengeLength');
  String get operationsToPractise => _text('operationsToPractise');
  String get start => _text('start');
  String get leaderboard => _text('leaderboard');
  String get howScoringWorks => _text('howScoringWorks');
  String get scoreFast => _text('scoreFast');
  String get scoreMedium => _text('scoreMedium');
  String get scoreSlow => _text('scoreSlow');
  String get scoreRepeat => _text('scoreRepeat');
  String get player => _text('player');
  String get quit => _text('quit');
  String get gameOver => _text('gameOver');
  String get noScoresYet => _text('noScoresYet');
  String get home => _text('home');
  String get playAgain => _text('playAgain');
  String get greatJob => _text('greatJob');
  String get choosePlayer => _text('choosePlayer');
  String get noPlayersYet => _text('noPlayersYet');
  String get newPlayer => _text('newPlayer');
  String get addPlayer => _text('addPlayer');
  String get changePlayer => _text('changePlayer');
  String get language => _text('language');
  String get history => _text('history');
  String get faults => _text('faults');
  String get gamesPlayed => _text('gamesPlayed');
  String get bestScore => _text('bestScore');
  String get noHistoryYet => _text('noHistoryYet');
  String get statistics => _text('statistics');
  String get tapToPlay => _text('tapToPlay');
  String get playAs => _text('playAs');

  /// The endonym (native name) of a supported language, used in the language
  /// switcher. These intentionally are not translated.
  static String languageName(String code) {
    switch (code) {
      case 'sk':
        return 'Slovenčina';
      case 'cs':
        return 'Čeština';
      case 'ru':
        return 'Русский';
      case 'de':
        return 'Deutsch';
      case 'zh':
        return '中文';
      case 'en':
      default:
        return 'English';
    }
  }

  String niceFeedback(String points) => _format('nice', {'points': points});

  String slowFeedback() => _text('slow');

  String oopsFeedback(int answer) => _format('oops', {'answer': '$answer'});

  String scoreLabel(int score) => _format('score', {'score': '$score'});

  String correctAccuracyLabel({
    required int correct,
    required int answered,
    required int accuracy,
  }) {
    return _format(
      'correctAccuracy',
      {
        'correct': '$correct',
        'answered': '$answered',
        'accuracy': '$accuracy',
      },
    );
  }

  String durationLabel(ChallengeDuration duration) {
    switch (duration) {
      case ChallengeDuration.oneMinute:
        return _text('duration1');
      case ChallengeDuration.twoMinutes:
        return _text('duration2');
      case ChallengeDuration.fiveMinutes:
        return _text('duration5');
    }
  }

  String operationLabel(OperationType operation) {
    switch (operation) {
      case OperationType.addition:
        return _text('addition');
      case OperationType.subtraction:
        return _text('subtraction');
      case OperationType.multiplication:
        return _text('multiplication');
      case OperationType.division:
        return _text('division');
    }
  }

  String _text(String key) => _strings[key] ?? _localizedValues['en']![key]!;

  String _format(String key, Map<String, String> values) {
    var text = _text(key);
    for (final entry in values.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }
}

extension AppStringsX on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
