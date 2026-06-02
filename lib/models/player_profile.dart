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
  }) : petCareUpdatedAt = petCareUpdatedAt ?? DateTime.now();

  final String name;
  final String languageCode;
  final PetType? petType;
  final int petFeedingPoints;
  final int petEnjoymentPoints;
  final DateTime petCareUpdatedAt;

  bool get hasPet => petType != null;

  PlayerProfile copyWith({
    String? name,
    String? languageCode,
    PetType? petType,
    int? petFeedingPoints,
    int? petEnjoymentPoints,
    DateTime? petCareUpdatedAt,
  }) =>
      PlayerProfile(
        name: name ?? this.name,
        languageCode: languageCode ?? this.languageCode,
        petType: petType ?? this.petType,
        petFeedingPoints: petFeedingPoints ?? this.petFeedingPoints,
        petEnjoymentPoints: petEnjoymentPoints ?? this.petEnjoymentPoints,
        petCareUpdatedAt: petCareUpdatedAt ?? this.petCareUpdatedAt,
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
    );
  }

  PetCare petCare({DateTime? now}) {
    final current = now ?? DateTime.now();
    final elapsedDays = current.difference(petCareUpdatedAt).inDays;
    return PetCare(
      feedingPoints: (petFeedingPoints - (elapsedDays * 100)).clamp(0, 100),
      enjoymentPoints:
          (petEnjoymentPoints - (elapsedDays * 20)).clamp(0, 100),
    );
  }

  PlayerProfile withUpdatedPetCare({
    int feedingDelta = 0,
    int enjoymentDelta = 0,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final care = petCare(now: current);
    return copyWith(
      petFeedingPoints: (care.feedingPoints + feedingDelta).clamp(0, 100),
      petEnjoymentPoints: (care.enjoymentPoints + enjoymentDelta).clamp(0, 100),
      petCareUpdatedAt: current,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'languageCode': languageCode,
        'petType': petType?.id,
        'petFeedingPoints': petFeedingPoints,
        'petEnjoymentPoints': petEnjoymentPoints,
        'petCareUpdatedAt': petCareUpdatedAt.millisecondsSinceEpoch,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        name: (json['name'] ?? '').toString(),
        languageCode: (json['languageCode'] ?? 'en').toString(),
        petType: PetTypeX.fromId(json['petType']?.toString()),
        petFeedingPoints: (json['petFeedingPoints'] as num?)?.toInt() ?? 0,
        petEnjoymentPoints: (json['petEnjoymentPoints'] as num?)?.toInt() ?? 0,
        petCareUpdatedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['petCareUpdatedAt'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
      );
}
