import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/background_style.dart';

/// A player's coin balance together with the button styles they own and how
/// those styles are assigned to the six game positions.
class CoinWallet {
  CoinWallet({
    required this.coins,
    required List<String> purchasedStyleIds,
    required List<String> assignments,
  })  : purchasedStyleIds = List.unmodifiable(purchasedStyleIds),
        assignments = List.unmodifiable(_normalizeAssignments(assignments));

  /// Current coin balance.
  final int coins;

  /// Ids of the (non-default) styles the player has bought.
  final List<String> purchasedStyleIds;

  /// Style id assigned to each of the [BackgroundStyle.positions] positions.
  final List<String> assignments;

  /// The default wallet for a brand new player: no coins, only the free styles,
  /// each default style on its matching position.
  factory CoinWallet.initial() => CoinWallet(
        coins: 0,
        purchasedStyleIds: const [],
        assignments: defaultAssignments(),
      );

  /// The default position -> style assignment (`default-0` on position 0, …).
  static List<String> defaultAssignments() =>
      [for (var i = 0; i < BackgroundStyle.positions; i++) 'default-$i'];

  /// Every style id the player can use: the always-free defaults plus anything
  /// they purchased.
  Set<String> get ownedStyleIds => {
        for (final style in BackgroundStyle.defaults) style.id,
        ...purchasedStyleIds,
      };

  CoinWallet copyWith({
    int? coins,
    List<String>? purchasedStyleIds,
    List<String>? assignments,
  }) =>
      CoinWallet(
        coins: coins ?? this.coins,
        purchasedStyleIds: purchasedStyleIds ?? this.purchasedStyleIds,
        assignments: assignments ?? this.assignments,
      );

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'purchased': purchasedStyleIds,
        'assignments': assignments,
      };

  factory CoinWallet.fromJson(Map<String, dynamic> json) {
    final purchased = (json['purchased'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final assignments = (json['assignments'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        defaultAssignments();
    return CoinWallet(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      purchasedStyleIds: purchased,
      assignments: assignments,
    );
  }

  /// Pads or trims a stored assignment list to exactly
  /// [BackgroundStyle.positions] entries, falling back to the matching default
  /// style for any missing or empty slot.
  static List<String> _normalizeAssignments(List<String> stored) {
    return [
      for (var i = 0; i < BackgroundStyle.positions; i++)
        (i < stored.length && stored[i].isNotEmpty) ? stored[i] : 'default-$i',
    ];
  }
}

/// Persists a [CoinWallet] per player (keyed by player name) using
/// shared_preferences. Coins, owned styles and position assignments all live
/// here.
class CoinService {
  static const String _key = 'wallets_v1';

  Future<Map<String, CoinWallet>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String, CoinWallet>{};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (name, value) => MapEntry(
          name,
          CoinWallet.fromJson(value as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      return <String, CoinWallet>{};
    }
  }

  Future<void> _saveAll(Map<String, CoinWallet> wallets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(wallets.map((name, wallet) => MapEntry(name, wallet.toJson()))),
    );
  }

  /// Loads the wallet for [playerName], or a fresh default wallet if the player
  /// has none yet.
  Future<CoinWallet> load(String playerName) async {
    final all = await _loadAll();
    return all[playerName] ?? CoinWallet.initial();
  }

  Future<CoinWallet> _update(String playerName, CoinWallet wallet) async {
    final all = await _loadAll();
    all[playerName] = wallet;
    await _saveAll(all);
    return wallet;
  }

  /// Adds [amount] coins to [playerName]'s balance and returns the new wallet.
  Future<CoinWallet> addCoins(String playerName, int amount) async {
    if (amount <= 0) return load(playerName);
    final wallet = await load(playerName);
    return _update(playerName, wallet.copyWith(coins: wallet.coins + amount));
  }

  /// Attempts to spend [amount] coins. Returns the updated wallet on success,
  /// or `null` if the player cannot afford it.
  Future<CoinWallet?> spendCoins(String playerName, int amount) async {
    if (amount <= 0) return load(playerName);
    final wallet = await load(playerName);
    if (wallet.coins < amount) return null;
    return _update(playerName, wallet.copyWith(coins: wallet.coins - amount));
  }

  /// Attempts to buy [style] for [playerName]. Returns the updated wallet on
  /// success, or `null` if the player cannot afford it or already owns it.
  Future<CoinWallet?> purchase(String playerName, BackgroundStyle style) async {
    final wallet = await load(playerName);
    if (wallet.ownedStyleIds.contains(style.id)) return null;
    if (wallet.coins < style.price) return null;
    final updated = wallet.copyWith(
      coins: wallet.coins - style.price,
      purchasedStyleIds: [...wallet.purchasedStyleIds, style.id],
    );
    return _update(playerName, updated);
  }

  /// Assigns the owned [styleId] to [position] (0-based) and returns the
  /// updated wallet. Unknown positions or styles the player does not own are
  /// ignored.
  Future<CoinWallet> assign(
    String playerName,
    int position,
    String styleId,
  ) async {
    final wallet = await load(playerName);
    if (position < 0 || position >= BackgroundStyle.positions) return wallet;
    if (!wallet.ownedStyleIds.contains(styleId)) return wallet;
    final assignments = [...wallet.assignments];
    assignments[position] = styleId;
    return _update(playerName, wallet.copyWith(assignments: assignments));
  }
}
