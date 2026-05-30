import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/models/background_style.dart';
import 'package:math_game_2/services/coin_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a new player starts with no coins and the default assignments',
      () async {
    final service = CoinService();
    final wallet = await service.load('Ann');
    expect(wallet.coins, 0);
    expect(wallet.purchasedStyleIds, isEmpty);
    expect(wallet.assignments, CoinWallet.defaultAssignments());
    expect(wallet.assignments.length, BackgroundStyle.positions);
  });

  test('coins accumulate and persist', () async {
    final service = CoinService();
    await service.addCoins('Ann', 20);
    await service.addCoins('Ann', 5);
    final wallet = await service.load('Ann');
    expect(wallet.coins, 25);
  });

  test('coins are tracked per player', () async {
    final service = CoinService();
    await service.addCoins('Ann', 20);
    await service.addCoins('Bob', 7);
    expect((await service.load('Ann')).coins, 20);
    expect((await service.load('Bob')).coins, 7);
  });

  test('purchasing deducts the price and unlocks the style', () async {
    final service = CoinService();
    final style = BackgroundStyle.generated(0);
    await service.addCoins('Ann', style.price + 50);

    final updated = await service.purchase('Ann', style);
    expect(updated, isNotNull);
    expect(updated!.coins, 50);
    expect(updated.purchasedStyleIds, contains(style.id));
    expect(updated.ownedStyleIds, contains(style.id));
  });

  test('purchasing fails without enough coins or when already owned', () async {
    final service = CoinService();
    final style = BackgroundStyle.generated(0);
    // Not enough coins.
    expect(await service.purchase('Ann', style), isNull);

    await service.addCoins('Ann', style.price);
    expect(await service.purchase('Ann', style), isNotNull);
    // Already owned -> second purchase is rejected (and not double charged).
    expect(await service.purchase('Ann', style), isNull);
    expect((await service.load('Ann')).coins, 0);
  });

  test('assigning a position only accepts owned styles', () async {
    final service = CoinService();
    // Default styles are always owned.
    var wallet = await service.assign('Ann', 0, 'default-2');
    expect(wallet.assignments[0], 'default-2');

    // A style the player does not own is ignored.
    wallet = await service.assign('Ann', 1, 'style-5');
    expect(wallet.assignments[1], 'default-1');

    // After buying it, the assignment sticks.
    final style = BackgroundStyle.generated(5);
    await service.addCoins('Ann', style.price);
    await service.purchase('Ann', style);
    wallet = await service.assign('Ann', 1, 'style-5');
    expect(wallet.assignments[1], 'style-5');
  });
}
