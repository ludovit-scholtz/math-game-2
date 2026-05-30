import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/background_style.dart';
import '../services/coin_service.dart';
import '../theme.dart';

/// Lets the player assign one of their owned button styles to each of the six
/// game positions. A live preview at the top shows how the answer buttons will
/// look in game.
class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({super.key, required this.playerName});

  final String playerName;

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
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

  BackgroundStyle _styleFor(String id, int position) =>
      BackgroundCatalog.byId(id) ?? BackgroundStyle.defaults[position];

  Future<void> _pickStyle(int position) async {
    final wallet = _wallet;
    if (wallet == null) return;
    final owned = BackgroundCatalog.ownedStyles(wallet.purchasedStyleIds);
    final strings = context.strings;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                strings.chooseStyle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: owned.length,
                itemBuilder: (context, index) {
                  final style = owned[index];
                  final selected = wallet.assignments[position] == style.id;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).pop(style.id),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: style.gradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Center(
                              child: Icon(Icons.check_circle,
                                  color: Colors.white, size: 28),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    final updated = await _service.assign(widget.playerName, position, chosen);
    if (!mounted) return;
    setState(() => _wallet = updated);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final wallet = _wallet;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.customize),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loading || wallet == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    strings.assignStyles,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: BackgroundStyle.positions,
                    itemBuilder: (context, position) {
                      final style =
                          _styleFor(wallet.assignments[position], position);
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _pickStyle(position),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: style.gradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  '${position + 1}',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Positioned(
                                top: 6,
                                right: 6,
                                child: Icon(Icons.edit,
                                    color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
