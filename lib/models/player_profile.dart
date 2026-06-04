import 'pet.dart';

/// A saved player together with their preferred language.
///
/// Profiles let a player pick their name from a list instead of typing it in
/// every time they swap with another player, and remember each player's chosen
/// language.
class PlayerProfile {
  PlayerProfile({
    required this.name,
    required this.languageCode,
    this.petType,
    this.petFeedingPoints = 0,
    this.petEnjoymentPoints = 0,
    DateTime? petCareUpdatedAt,
    DateTime? petFeedingUpdatedAt,
    DateTime? petEnjoymentUpdatedAt,
  })  : petCareUpdatedAt = petCareUpdatedAt ?? DateTime.now(),
        petFeedingUpdatedAt =
            petFeedingUpdatedAt ?? petCareUpdatedAt ?? DateTime.now(),
        petEnjoymentUpdatedAt =
            petEnjoymentUpdatedAt ?? petCareUpdatedAt ?? DateTime.now();

  static const int _pointsPerDay = 100;
  static const int _minutesPerDay = 24 * 60;
  static const double _feedingMinutesPerPoint = _minutesPerDay / 100;
  static const double _enjoymentMinutesPerPoint = _minutesPerDay / 20;

  final String name;
  final String languageCode;
  final PetType? petType;
  final int petFeedingPoints;
  final int petEnjoymentPoints;
  final DateTime petCareUpdatedAt;
  final DateTime petFeedingUpdatedAt;
  final DateTime petEnjoymentUpdatedAt;

  bool get hasPet => petType != null;

  PlayerProfile copyWith({
    String? name,
    String? languageCode,
    PetType? petType,
    int? petFeedingPoints,
    int? petEnjoymentPoints,
    DateTime? petCareUpdatedAt,
    DateTime? petFeedingUpdatedAt,
    DateTime? petEnjoymentUpdatedAt,
  }) =>
      PlayerProfile(
        name: name ?? this.name,
        languageCode: languageCode ?? this.languageCode,
        petType: petType ?? this.petType,
        petFeedingPoints: petFeedingPoints ?? this.petFeedingPoints,
        petEnjoymentPoints: petEnjoymentPoints ?? this.petEnjoymentPoints,
        petCareUpdatedAt: petCareUpdatedAt ?? this.petCareUpdatedAt,
        petFeedingUpdatedAt: petFeedingUpdatedAt ?? this.petFeedingUpdatedAt,
        petEnjoymentUpdatedAt:
            petEnjoymentUpdatedAt ?? this.petEnjoymentUpdatedAt,
      );

  PlayerProfile withPet(PetType type, {DateTime? now}) {
    final selectedAt = now ?? DateTime.now();
    return PlayerProfile(
      name: name,
      languageCode: languageCode,
      petType: type,
      petFeedingPoints: 100,
      petEnjoymentPoints: 100,
      petCareUpdatedAt: selectedAt,
      petFeedingUpdatedAt: selectedAt,
      petEnjoymentUpdatedAt: selectedAt,
    );
  }

  PetCare petCare({DateTime? now}) {
    final current = now ?? DateTime.now();
    return PetCare(
      feedingPoints: _decayedPoints(
        petFeedingPoints,
        petFeedingUpdatedAt,
        current,
        _feedingMinutesPerPoint,
      ),
      enjoymentPoints: _decayedPoints(
        petEnjoymentPoints,
        petEnjoymentUpdatedAt,
        current,
        _enjoymentMinutesPerPoint,
      ),
    );
  }

  DateTime? nextPetCareBelow({required int threshold, DateTime? now}) {
    if (!hasPet) return null;
    final current = now ?? DateTime.now();
    final feedingAt = _thresholdTime(
      petFeedingPoints,
      petFeedingUpdatedAt,
      current,
      _feedingMinutesPerPoint,
      threshold,
    );
    final enjoymentAt = _thresholdTime(
      petEnjoymentPoints,
      petEnjoymentUpdatedAt,
      current,
      _enjoymentMinutesPerPoint,
      threshold,
    );
    if (feedingAt == null) return enjoymentAt;
    if (enjoymentAt == null) return feedingAt;
    return feedingAt.isBefore(enjoymentAt) ? feedingAt : enjoymentAt;
  }

  static int _decayedPoints(
    int points,
    DateTime updatedAt,
    DateTime current,
    double minutesPerPoint,
  ) {
    final elapsedMilliseconds = current.difference(updatedAt).inMilliseconds;
    if (elapsedMilliseconds <= 0) return points.clamp(0, _pointsPerDay);
    final millisecondsPerPoint = minutesPerPoint * 60 * 1000;
    final lostPoints = (elapsedMilliseconds / millisecondsPerPoint).floor();
    return (points - lostPoints).clamp(0, _pointsPerDay);
  }

  static DateTime? _thresholdTime(
    int points,
    DateTime updatedAt,
    DateTime current,
    double minutesPerPoint,
    int threshold,
  ) {
    if (points <= threshold) return current;
    final pointsToLose = points - threshold;
    final thresholdAt = updatedAt.add(
      Duration(
        milliseconds: (pointsToLose * minutesPerPoint * 60 * 1000).ceil(),
      ),
    );
    return thresholdAt.isBefore(current) ? current : thresholdAt;
  }

  PlayerProfile withUpdatedPetCare({
    int feedingDelta = 0,
    int enjoymentDelta = 0,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final care = petCare(now: current);
    final updatesFeeding = feedingDelta != 0;
    final updatesEnjoyment = enjoymentDelta != 0;
    return copyWith(
      petFeedingPoints: updatesFeeding
          ? (care.feedingPoints + feedingDelta).clamp(0, 100)
          : petFeedingPoints,
      petEnjoymentPoints: updatesEnjoyment
          ? (care.enjoymentPoints + enjoymentDelta).clamp(0, 100)
          : petEnjoymentPoints,
      petCareUpdatedAt: current,
      petFeedingUpdatedAt: updatesFeeding ? current : petFeedingUpdatedAt,
      petEnjoymentUpdatedAt:
          updatesEnjoyment ? current : petEnjoymentUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'languageCode': languageCode,
        'petType': petType?.id,
        'petFeedingPoints': petFeedingPoints,
        'petEnjoymentPoints': petEnjoymentPoints,
        'petCareUpdatedAt': petCareUpdatedAt.millisecondsSinceEpoch,
        'petFeedingUpdatedAt': petFeedingUpdatedAt.millisecondsSinceEpoch,
        'petEnjoymentUpdatedAt': petEnjoymentUpdatedAt.millisecondsSinceEpoch,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final careUpdatedMillis =
        (json['petCareUpdatedAt'] as num?)?.toInt() ?? nowMillis;
    final feedingUpdatedMillis =
        (json['petFeedingUpdatedAt'] as num?)?.toInt() ?? careUpdatedMillis;
    final enjoymentUpdatedMillis =
        (json['petEnjoymentUpdatedAt'] as num?)?.toInt() ?? careUpdatedMillis;
    return PlayerProfile(
      name: (json['name'] ?? '').toString(),
      languageCode: (json['languageCode'] ?? 'en').toString(),
      petType: PetTypeX.fromId(json['petType']?.toString()),
      petFeedingPoints: (json['petFeedingPoints'] as num?)?.toInt() ?? 0,
      petEnjoymentPoints: (json['petEnjoymentPoints'] as num?)?.toInt() ?? 0,
      petCareUpdatedAt: DateTime.fromMillisecondsSinceEpoch(careUpdatedMillis),
      petFeedingUpdatedAt:
          DateTime.fromMillisecondsSinceEpoch(feedingUpdatedMillis),
      petEnjoymentUpdatedAt:
          DateTime.fromMillisecondsSinceEpoch(enjoymentUpdatedMillis),
    );
  }
}
