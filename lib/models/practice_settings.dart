import 'game_config.dart';
import 'operation_type.dart';

/// The largest number a question's operands and answers may reach.
enum NumberRange { within5, within10, within20, within100, within1000 }

extension NumberRangeX on NumberRange {
  int get max {
    switch (this) {
      case NumberRange.within5:
        return 5;
      case NumberRange.within10:
        return 10;
      case NumberRange.within20:
        return 20;
      case NumberRange.within100:
        return 100;
      case NumberRange.within1000:
        return 1000;
    }
  }

  String get id => name;

  /// Language independent label, e.g. `1–20`.
  String get label => '1–$max';

  static NumberRange? fromId(String? id) {
    for (final value in NumberRange.values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// Whether addition/subtraction questions cross a ten (carry or borrow).
enum CrossingMode {
  /// Never carry or borrow, e.g. `23 + 14`, `38 − 15`.
  none,

  /// Carrying/borrowing happens whenever it happens to (the classic mix).
  mixed,

  /// Always carry or borrow, e.g. `15 + 16`, `32 − 13`, `8 + 5`.
  only,
}

extension CrossingModeX on CrossingMode {
  String get id => name;

  static CrossingMode? fromId(String? id) {
    for (final value in CrossingMode.values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// Focused exercises that follow the strategies children are taught.
enum Drill {
  plusMinusOne,
  doubles,
  nearDoubles,
  pairsToTen,
  pairsToHundred,
  bridgeTen,
  missingNumber,
}

extension DrillX on Drill {
  String get id => name;

  /// A language independent example shown next to the (translated) name.
  String get example {
    switch (this) {
      case Drill.plusMinusOne:
        return '±1 ±2';
      case Drill.doubles:
        return '6 + 6';
      case Drill.nearDoubles:
        return '6 + 7';
      case Drill.pairsToTen:
        return '7 + ? = 10';
      case Drill.pairsToHundred:
        return '35 + ? = 100';
      case Drill.bridgeTen:
        return '8 + 5';
      case Drill.missingNumber:
        return '3 + ? = 8';
    }
  }

  static Drill? fromId(String? id) {
    for (final value in Drill.values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// One-tap starting points in the parental control panel.
enum PracticePreset { starting, within20, within100, within1000 }

/// What a parent allows a child to practise. Settings are stored per player.
class PracticeSettings {
  PracticeSettings({
    Set<OperationType>? operations,
    this.range = NumberRange.within100,
    this.crossing = CrossingMode.mixed,
    Set<Drill>? drills,
    Set<int>? tables,
    Set<ChallengeDuration>? durations,
  }) : operations = Set.unmodifiable(operations ?? OperationType.values),
       drills = Set.unmodifiable(drills ?? const <Drill>{}),
       tables = Set.unmodifiable(
         (tables == null || tables.isEmpty) ? defaultTables : tables,
       ),
       durations = Set.unmodifiable(
         (durations == null || durations.isEmpty)
             ? ChallengeDuration.values
             : durations,
       );

  /// Multiplication tables a parent can switch on (`×1` is not offered).
  static const int minTable = 2;
  static const int maxTable = 10;

  static Set<int> get defaultTables => {
    for (var t = minTable; t <= maxTable; t++) t,
  };

  /// The operations the child may pick on the home screen.
  final Set<OperationType> operations;
  final NumberRange range;
  final CrossingMode crossing;

  /// The focused exercises the child may pick on the home screen.
  final Set<Drill> drills;

  /// Tables used by multiplication and division (`2..10`).
  final Set<int> tables;
  final Set<ChallengeDuration> durations;

  /// The classic behaviour of the game before parental control existed.
  factory PracticeSettings.defaults() => PracticeSettings();

  factory PracticeSettings.preset(PracticePreset preset) {
    switch (preset) {
      case PracticePreset.starting:
        return PracticeSettings(
          operations: {OperationType.addition, OperationType.subtraction},
          range: NumberRange.within10,
          crossing: CrossingMode.none,
          drills: {Drill.pairsToTen},
        );
      case PracticePreset.within20:
        return PracticeSettings(
          operations: {OperationType.addition, OperationType.subtraction},
          range: NumberRange.within20,
          crossing: CrossingMode.mixed,
          drills: {
            Drill.doubles,
            Drill.nearDoubles,
            Drill.pairsToTen,
            Drill.bridgeTen,
          },
        );
      case PracticePreset.within100:
        return PracticeSettings();
      case PracticePreset.within1000:
        return PracticeSettings(range: NumberRange.within1000);
    }
  }

  /// These settings with [preset]'s operations, range, crossing and drills.
  /// The parent's tables and challenge lengths are kept, so choosing a preset
  /// never silently drops those restrictions.
  PracticeSettings withPreset(PracticePreset preset) {
    final base = PracticeSettings.preset(preset);
    return PracticeSettings(
      operations: base.operations,
      range: base.range,
      crossing: base.crossing,
      drills: base.drills,
      tables: tables,
      durations: durations,
    );
  }

  /// The preset these settings match (ignoring tables and challenge lengths).
  PracticePreset? get matchingPreset {
    for (final preset in PracticePreset.values) {
      if (this == withPreset(preset)) return preset;
    }
    return null;
  }

  /// Settings must always allow at least one thing to practise.
  bool get hasAnythingToPractise => operations.isNotEmpty || drills.isNotEmpty;

  PracticeSettings copyWith({
    Set<OperationType>? operations,
    NumberRange? range,
    CrossingMode? crossing,
    Set<Drill>? drills,
    Set<int>? tables,
    Set<ChallengeDuration>? durations,
  }) => PracticeSettings(
    operations: operations ?? this.operations,
    range: range ?? this.range,
    crossing: crossing ?? this.crossing,
    drills: drills ?? this.drills,
    tables: tables ?? this.tables,
    durations: durations ?? this.durations,
  ).normalized();

  /// Repairs combinations that cannot produce questions.
  PracticeSettings normalized() {
    var ops = operations;
    if (ops.isEmpty && drills.isEmpty) ops = {...OperationType.values};
    var cross = crossing;
    // Nothing within 5 carries over a ten.
    if (range == NumberRange.within5 && cross == CrossingMode.only) {
      cross = CrossingMode.mixed;
    }
    if (ops == operations && cross == crossing) return this;
    return PracticeSettings(
      operations: ops,
      range: range,
      crossing: cross,
      drills: drills,
      tables: tables,
      durations: durations,
    );
  }

  /// A language independent key describing the *difficulty* of a game, used to
  /// keep leaderboards and top scores of different modes apart. Empty for the
  /// classic mode so existing history keeps its leaderboards.
  static String modeKeyFor({
    required Set<OperationType> operations,
    required Set<Drill> drills,
    required PracticeSettings settings,
  }) {
    final parts = <String>[];
    final usesRange =
        operations.contains(OperationType.addition) ||
        operations.contains(OperationType.subtraction) ||
        drills.isNotEmpty;
    if (usesRange) {
      if (settings.range != NumberRange.within100) {
        parts.add(settings.range.id);
      }
      if (settings.crossing != CrossingMode.mixed) {
        parts.add('x-${settings.crossing.id}');
      }
    }
    if (drills.isNotEmpty) {
      final ids = drills.map((d) => d.id).toList()..sort();
      parts.add('d-${ids.join('+')}');
    }
    final usesTables =
        operations.contains(OperationType.multiplication) ||
        operations.contains(OperationType.division);
    if (usesTables && !_sameSet(settings.tables, defaultTables)) {
      final sorted = settings.tables.toList()..sort();
      parts.add('t-${sorted.join(',')}');
    }
    return parts.join('|');
  }

  Map<String, dynamic> toJson() => {
    'operations': operations.map((o) => o.storageKey).toList(),
    'range': range.id,
    'crossing': crossing.id,
    'drills': drills.map((d) => d.id).toList(),
    'tables': (tables.toList()..sort()),
    'durations': durations.map((d) => d.index).toList(),
  };

  factory PracticeSettings.fromJson(Map<String, dynamic> json) {
    final ops = <OperationType>{};
    for (final raw in (json['operations'] as List<dynamic>?) ?? const []) {
      for (final op in OperationType.values) {
        if (op.storageKey == raw.toString()) ops.add(op);
      }
    }
    final drills = <Drill>{};
    for (final raw in (json['drills'] as List<dynamic>?) ?? const []) {
      final drill = DrillX.fromId(raw.toString());
      if (drill != null) drills.add(drill);
    }
    final tables = <int>{};
    for (final raw in (json['tables'] as List<dynamic>?) ?? const []) {
      final table = raw is num ? raw.toInt() : int.tryParse(raw.toString());
      if (table != null && table >= minTable && table <= maxTable) {
        tables.add(table);
      }
    }
    final durations = <ChallengeDuration>{};
    for (final raw in (json['durations'] as List<dynamic>?) ?? const []) {
      final index = raw is num ? raw.toInt() : int.tryParse(raw.toString());
      if (index != null &&
          index >= 0 &&
          index < ChallengeDuration.values.length) {
        durations.add(ChallengeDuration.values[index]);
      }
    }
    return PracticeSettings(
      // A stored list that is missing or empty falls back to the defaults,
      // unless drills carry the settings.
      operations: ops.isEmpty && drills.isEmpty ? null : ops,
      range:
          NumberRangeX.fromId(json['range']?.toString()) ??
          NumberRange.within100,
      crossing:
          CrossingModeX.fromId(json['crossing']?.toString()) ??
          CrossingMode.mixed,
      drills: drills,
      tables: tables,
      durations: durations,
    ).normalized();
  }

  @override
  bool operator ==(Object other) =>
      other is PracticeSettings &&
      _sameSet(other.operations, operations) &&
      other.range == range &&
      other.crossing == crossing &&
      _sameSet(other.drills, drills) &&
      _sameSet(other.tables, tables) &&
      _sameSet(other.durations, durations);

  @override
  int get hashCode => Object.hash(
    range,
    crossing,
    operations.length,
    drills.length,
    tables.length,
    durations.length,
  );

  static bool _sameSet<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}
