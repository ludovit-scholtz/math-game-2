enum PetType {
  cat,
  dog,
  panda,
  rabbit,
}

enum PetMood {
  happy,
  hungry,
  sad,
}

class PetCare {
  const PetCare({
    required this.feedingPoints,
    required this.enjoymentPoints,
  });

  final int feedingPoints;
  final int enjoymentPoints;

  PetMood get mood {
    if (enjoymentPoints < 20) return PetMood.sad;
    if (feedingPoints < 20) return PetMood.hungry;
    return PetMood.happy;
  }
}

extension PetTypeX on PetType {
  String get id => name;

  String get label {
    switch (this) {
      case PetType.cat:
        return 'Cat';
      case PetType.dog:
        return 'Dog';
      case PetType.panda:
        return 'Panda';
      case PetType.rabbit:
        return 'Rabbit';
    }
  }

  String asset(PetMood mood) => 'assets/pets/$id-${mood.name}.png';

  static PetType? fromId(String? id) {
    for (final type in PetType.values) {
      if (type.id == id) return type;
    }
    return null;
  }
}