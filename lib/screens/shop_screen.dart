import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/background_style.dart';
import '../services/coin_service.dart';
import '../theme.dart';

/// The in-game eshop where players spend coins to unlock new button background
/// styles. The shop always offers [BackgroundCatalog.shopSize] styles the
/// player does not own yet; every style has a fixed price that is identical for
/// every player.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.playerName});

  final String playerName;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final CoinService _service = CoinService();

  CoinWallet? _wallet;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final wallet = await _service.load(widget.playerName);
    if (!mounted) return;
    setState(() {
      _wallet = wallet;
      _loading = false;
    });
  }

  Future<void> _buy(BackgroundStyle style) async {
    final updated = await _service.purchase(widget.playerName, style);
    if (!mounted) return;
    final strings = context.strings;
    if (updated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.notEnoughCoins)),
      );
      return;
    }
    setState(() => _wallet = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.purchasedStyle(style.name))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final wallet = _wallet;
    final available = wallet == null
        ? <BackgroundStyle>[]
        : BackgroundCatalog.availableFor(wallet.ownedStyleIds);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.shop),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '🪙 ${strings.coinCount(wallet?.coins ?? 0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final style = available[index];
                  final canAfford = (wallet?.coins ?? 0) >= style.price;
                  return _ShopTile(
                    style: style,
                    canAfford: canAfford,
                    buyLabel: strings.buy,
                    priceLabel: strings.coinCount(style.price),
                    onBuy: canAfford ? () => _buy(style) : null,
                  );
                },
              ),
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.style,
    required this.canAfford,
    required this.buyLabel,
    required this.priceLabel,
    required this.onBuy,
  });

  final BackgroundStyle style;
  final bool canAfford;
  final String buyLabel;
  final String priceLabel;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: style.gradient),
              child: const Center(
                child: Text(
                  '42',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBuy,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text('$buyLabel  🪙 $priceLabel'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
