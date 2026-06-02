import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/models/background_style.dart';

void main() {
  group('BackgroundStyle pricing', () {
    test('prices are always within 50..1000 and rounded to tens', () {
      for (var i = 0; i < 1000; i++) {
        final price = BackgroundStyle.priceForIndex(i);
        expect(price, inInclusiveRange(BackgroundStyle.budgetPrice, 1000));
        expect(price % 10, 0);
      }
    });

    test('every fifth generated style is a 50 coin budget style', () {
      for (var i = 0; i < 100; i++) {
        final expected = i % 5 == 0;
        expect(
          BackgroundStyle.priceForIndex(i) == BackgroundStyle.budgetPrice,
          expected,
        );
      }
    });

    test('prices and styles are stable (same for every player)', () {
      for (var i = 0; i < 100; i++) {
        expect(BackgroundStyle.priceForIndex(i),
            BackgroundStyle.priceForIndex(i));
        final a = BackgroundStyle.generated(i);
        final b = BackgroundStyle.generated(i);
        expect(a.id, b.id);
        expect(a.price, b.price);
        expect(
          a.colors.map((c) => c.toARGB32()),
          b.colors.map((c) => c.toARGB32()),
        );
      }
    });

    test('generated style price matches priceForIndex', () {
      for (var i = 0; i < 50; i++) {
        expect(BackgroundStyle.generated(i).price,
            BackgroundStyle.priceForIndex(i));
      }
    });
  });

  group('BackgroundCatalog', () {
    test('always offers the full shop size of unowned styles', () {
      final available = BackgroundCatalog.availableFor({});
      expect(available.length, BackgroundCatalog.shopSize);
      expect(available.map((s) => s.id).toSet().length,
          BackgroundCatalog.shopSize);
    });

    test('always includes budget 50 coin styles in the shop', () {
      final available = BackgroundCatalog.availableFor({});
      expect(
        available
            .where((style) => style.price == BackgroundStyle.budgetPrice)
            .length,
        greaterThanOrEqualTo(BackgroundCatalog.minimumBudgetStyles),
      );
      expect(available.take(BackgroundCatalog.minimumBudgetStyles).every(
            (style) => style.price == BackgroundStyle.budgetPrice,
          ),
          isTrue);
    });

    test('skips owned styles so the shop never runs dry', () {
      final owned = {
        for (var i = 0; i < 5; i++) 'style-$i',
      };
      final available = BackgroundCatalog.availableFor(owned);
      expect(available.length, BackgroundCatalog.shopSize);
      for (final style in available) {
        expect(owned.contains(style.id), isFalse);
      }
    });

    test('keeps budget styles available after cheap styles are purchased', () {
      final owned = {
        for (var i = 0; i <= 100; i += 5) 'style-$i',
      };
      final available = BackgroundCatalog.availableFor(owned);
      expect(available.length, BackgroundCatalog.shopSize);
      expect(
        available
            .where((style) => style.price == BackgroundStyle.budgetPrice)
            .length,
        greaterThanOrEqualTo(BackgroundCatalog.minimumBudgetStyles),
      );
      for (final style in available) {
        expect(owned.contains(style.id), isFalse);
      }
    });

    test('resolves both default and generated styles by id', () {
      expect(BackgroundCatalog.byId('default-0')?.id, 'default-0');
      expect(BackgroundCatalog.byId('style-3')?.id, 'style-3');
      expect(BackgroundCatalog.byId('nope'), isNull);
    });

    test('owned styles always include the six free defaults', () {
      final owned = BackgroundCatalog.ownedStyles(['style-1']);
      expect(owned.length, BackgroundStyle.defaults.length + 1);
      expect(owned.take(BackgroundStyle.defaults.length).map((s) => s.id),
          BackgroundStyle.defaults.map((s) => s.id));
      expect(owned.last.id, 'style-1');
    });
  });
}
