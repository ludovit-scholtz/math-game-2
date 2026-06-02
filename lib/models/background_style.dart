import 'package:flutter/material.dart';

/// A visual style applied to the number answer buttons in the game.
///
/// Styles come in two flavours:
///
/// * **Default** styles ([defaults]) are free, always owned and used for the
///   six positions before the player customises anything.
/// * **Generated** styles ([generated]) are the ones sold in the shop. They are
///   produced deterministically from an integer index, which means every player
///   sees the exact same style and the exact same [price] for a given index -
///   so a background always costs the same for everyone.
class BackgroundStyle {
  const BackgroundStyle({
    required this.id,
    required this.name,
    required this.price,
    required this.colors,
  });

  /// Stable identifier, e.g. `default-0` or `style-7`.
  final String id;

  /// A short decorative name shown in the shop. Not translated (like a proper
  /// name) so a style is recognisable in any language.
  final String name;

  /// Cost in coins. `0` for the free default styles.
  final int price;

  /// One or two colours describing the button background gradient.
  final List<Color> colors;

  bool get isFree => price == 0;

  /// The gradient used to paint a button with this style.
  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors.length == 1 ? [colors.first, colors.first] : colors,
      );

  /// Number of positions (answer buttons) shown in a game.
  static const int positions = 6;

  /// The lowest purchasable theme price used for budget-friendly shop options.
  static const int budgetPrice = 50;

  /// The free starter styles, one per button position.
  static const List<BackgroundStyle> defaults = [
    BackgroundStyle(
        id: 'default-0', name: 'Indigo', price: 0, colors: [Color(0xFF5B6CF0)]),
    BackgroundStyle(
        id: 'default-1', name: 'Mango', price: 0, colors: [Color(0xFFFF8A3D)]),
    BackgroundStyle(
        id: 'default-2', name: 'Meadow', price: 0, colors: [Color(0xFF2BB673)]),
    BackgroundStyle(
        id: 'default-3', name: 'Grape', price: 0, colors: [Color(0xFFB23CFD)]),
    BackgroundStyle(
        id: 'default-4', name: 'Lagoon', price: 0, colors: [Color(0xFF18B0C9)]),
    BackgroundStyle(
        id: 'default-5', name: 'Cherry', price: 0, colors: [Color(0xFFE5484D)]),
  ];

  /// A purchasable style derived deterministically from [index] (>= 0).
  static BackgroundStyle generated(int index) {
    assert(index >= 0);
    final h = _hash(index);
    final hue1 = (h % 360).toDouble();
    final hue2 = ((hue1 + 24 + (h ~/ 360) % 60) % 360).toDouble();
    final c1 = HSLColor.fromAHSL(1, hue1, 0.68, 0.55).toColor();
    final c2 = HSLColor.fromAHSL(1, hue2, 0.70, 0.45).toColor();
    return BackgroundStyle(
      id: 'style-$index',
      name: _nameForIndex(index),
      price: priceForIndex(index),
      colors: [c1, c2],
    );
  }

  /// The deterministic price (in coins) for the generated style at [index].
  /// Every fifth style costs [budgetPrice], while the rest stay in the inclusive
  /// range 100..1000 and are rounded to whole tens. Because it only depends on
  /// [index] every player pays the same amount.
  static int priceForIndex(int index) {
    if (index % 5 == 0) return budgetPrice;
    final raw = 100 + (_hash(index) % 901); // 100..1000
    return (raw ~/ 10) * 10;
  }

  static const List<String> _adjectives = [
    'Cosmic', 'Sunset', 'Velvet', 'Neon', 'Misty', 'Royal', 'Frost', 'Ember',
    'Aurora', 'Coral', 'Golden', 'Mystic', 'Electric', 'Tropic', 'Lunar',
    'Crimson', 'Jade', 'Amber', 'Twilight', 'Bubble',
  ];

  static const List<String> _nouns = [
    'Wave', 'Glow', 'Burst', 'Dream', 'Pop', 'Swirl', 'Flash', 'Mist',
    'Spark', 'Bloom', 'Drift', 'Shine', 'Pulse', 'Haze', 'Beam',
  ];

  static String _nameForIndex(int index) {
    final h = _hash(index);
    final adjective = _adjectives[h % _adjectives.length];
    final noun = _nouns[(h ~/ _adjectives.length) % _nouns.length];
    return '$adjective $noun';
  }

  /// A small, deterministic 31-bit hash. Stays within the integer range that is
  /// exactly representable on every platform (including web) so results are
  /// identical everywhere.
  static int _hash(int n) {
    var x = ((n + 1) * 2654435761) & 0x7fffffff;
    x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff;
    x = x ^ (x >> 16);
    return x & 0x7fffffff;
  }
}

/// Helpers for listing the styles available in the shop and resolving styles by
/// id.
class BackgroundCatalog {
  BackgroundCatalog._();

  /// How many purchasable styles the shop always offers.
  static const int shopSize = 20;

  /// How many budget-priced styles should be visible whenever possible.
  static const int minimumBudgetStyles = 4;

  /// Returns [shopSize] purchasable styles the player does not own yet. Because
  /// new styles are generated on demand, the shop never runs out: there are
  /// always at least [shopSize] fresh styles to buy.
  static List<BackgroundStyle> availableFor(Set<String> ownedIds) {
    final result = <BackgroundStyle>[];
    var index = 0;
    while (result.length < shopSize) {
      final style = BackgroundStyle.generated(index);
      if (!ownedIds.contains(style.id)) result.add(style);
      index++;
    }
    _ensureBudgetStyles(result, ownedIds);
    result.sort((a, b) {
      final priceOrder = a.price.compareTo(b.price);
      if (priceOrder != 0) return priceOrder;
      return _generatedIndex(a.id).compareTo(_generatedIndex(b.id));
    });
    return result;
  }

  static void _ensureBudgetStyles(
    List<BackgroundStyle> styles,
    Set<String> ownedIds,
  ) {
    final usedIds = styles.map((style) => style.id).toSet();
    var budgetCount = styles
        .where((style) => style.price == BackgroundStyle.budgetPrice)
        .length;
    var index = 0;

    while (budgetCount < minimumBudgetStyles) {
      final candidate = BackgroundStyle.generated(index);
      if (candidate.price == BackgroundStyle.budgetPrice &&
          !ownedIds.contains(candidate.id) &&
          usedIds.add(candidate.id)) {
        final replaceIndex = styles.lastIndexWhere(
          (style) => style.price != BackgroundStyle.budgetPrice,
        );
        if (replaceIndex < 0) return;
        styles[replaceIndex] = candidate;
        budgetCount++;
      }
      index++;
    }
  }

  /// Resolves a style by its [id], or `null` if the id is unknown.
  static BackgroundStyle? byId(String id) {
    for (final style in BackgroundStyle.defaults) {
      if (style.id == id) return style;
    }
    if (id.startsWith('style-')) {
      final n = int.tryParse(id.substring('style-'.length));
      if (n != null && n >= 0) return BackgroundStyle.generated(n);
    }
    return null;
  }

  /// All styles the player can assign to a position: the free defaults plus
  /// every style they have purchased, defaults first.
  static List<BackgroundStyle> ownedStyles(List<String> purchasedIds) {
    final styles = <BackgroundStyle>[...BackgroundStyle.defaults];
    for (final id in purchasedIds) {
      final style = byId(id);
      if (style != null && !styles.any((s) => s.id == style.id)) {
        styles.add(style);
      }
    }
    return styles;
  }

  static int _generatedIndex(String id) {
    if (!id.startsWith('style-')) return -1;
    return int.tryParse(id.substring('style-'.length)) ?? -1;
  }
}
