/// A saved player together with their preferred language.
///
/// Profiles let a player pick their name from a list instead of typing it in
/// every time they swap with another player, and remember each player's chosen
/// language.
class PlayerProfile {
  PlayerProfile({required this.name, required this.languageCode});

  final String name;
  final String languageCode;

  PlayerProfile copyWith({String? name, String? languageCode}) => PlayerProfile(
        name: name ?? this.name,
        languageCode: languageCode ?? this.languageCode,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'languageCode': languageCode,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        name: (json['name'] ?? '').toString(),
        languageCode: (json['languageCode'] ?? 'en').toString(),
      );
}
