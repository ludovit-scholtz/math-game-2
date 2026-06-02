import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/game_config.dart';
import '../models/operation_type.dart';
import '../models/player_profile.dart';
import '../services/coin_service.dart';
import '../services/player_service.dart';
import '../theme.dart';
import '../widgets/pet_widgets.dart';
import 'customization_screen.dart';
import 'docs_screen.dart';
import 'game_screen.dart';
import 'history_screen.dart';
import 'pet_screen.dart';
import 'player_select_screen.dart';
import 'privacy_policy_screen.dart';
import 'results_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

/// The first screen: pick (or switch) the player, a challenge length and which
/// operations to practise, then start playing.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlayerService _playerService = PlayerService();
  final CoinService _coinService = CoinService();

  PlayerProfile? _player;
  bool _loadingPlayer = true;
  int _coins = 0;

  ChallengeDuration _duration = ChallengeDuration.oneMinute;
  final Set<OperationType> _operations = {
    OperationType.addition,
    OperationType.subtraction,
  };

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    final player = await _playerService.loadCurrent();
    if (!mounted) return;
    setState(() {
      _player = player;
      _loadingPlayer = false;
    });
    if (player != null) {
      _loadCoins(player.name);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          MathGameApp.of(context).setLocale(Locale(player.languageCode));
        }
      });
    }
  }

  Future<void> _loadCoins(String name) async {
    final wallet = await _coinService.load(name);
    if (!mounted) return;
    setState(() => _coins = wallet.coins);
  }

  Future<PlayerProfile?> _choosePlayer() async {
    final selected = await Navigator.of(context).push<PlayerProfile>(
      MaterialPageRoute<PlayerProfile>(
        builder: (_) => const PlayerSelectScreen(),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _player = selected);
      _loadCoins(selected.name);
    }
    return selected;
  }

  Future<void> _openPetCare() async {
    final player = _player;
    if (player == null || !player.hasPet) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PetScreen(playerName: player.name),
      ),
    );
    if (!mounted) return;
    await _loadPlayer();
    await _loadCoins(player.name);
  }

  void _toggleOperation(OperationType type) {
    setState(() {
      if (_operations.contains(type)) {
        if (_operations.length > 1) _operations.remove(type);
      } else {
        _operations.add(type);
      }
    });
  }

  Future<void> _startGame() async {
    var player = _player;
    // If no player is selected, send the user to the selection screen first.
    if (player == null) {
      player = await _choosePlayer();
      if (player == null) return;
    }
    if (!mounted) return;
    final config = GameConfig(
      playerName: player.name,
      duration: _duration,
      operations: Set<OperationType>.from(_operations),
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameScreen(config: config)),
    );
    // Returning from a finished game may have awarded coins.
    if (mounted) {
      _loadCoins(player.name);
      _loadPlayer();
    }
  }

  Future<void> _openShop() async {
    final player = _player;
    if (player == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopScreen(playerName: player.name),
      ),
    );
    if (mounted) _loadCoins(player.name);
  }

  void _openCustomize() {
    final player = _player;
    if (player == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomizationScreen(playerName: player.name),
      ),
    );
  }

  void _openDocs() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DocsScreen()),
    );
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  void _openHistory() {
    final player = _player;
    if (player == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryScreen(playerName: player.name),
      ),
    );
  }

  void _openLeaderboard() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ResultsScreen()),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
    await _loadPlayer();
  }

  Future<void> _handleMenuAction(_HomeMenuAction action) async {
    switch (action) {
      case _HomeMenuAction.leaderboard:
        _openLeaderboard();
      case _HomeMenuAction.shop:
        await _openShop();
      case _HomeMenuAction.pet:
        await _openPetCare();
      case _HomeMenuAction.customize:
        _openCustomize();
      case _HomeMenuAction.history:
        _openHistory();
      case _HomeMenuAction.settings:
        await _openSettings();
      case _HomeMenuAction.docs:
        _openDocs();
      case _HomeMenuAction.privacyPolicy:
        _openPrivacyPolicy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<_HomeMenuAction>(
            tooltip: strings.settings,
            icon: const Icon(Icons.menu_rounded),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _HomeMenuAction.leaderboard,
                child: _MenuItem(
                  icon: Icons.emoji_events_outlined,
                  label: strings.leaderboard,
                ),
              ),
              if (_player != null) ...[
                PopupMenuItem(
                  value: _HomeMenuAction.history,
                  child: _MenuItem(
                    icon: Icons.history_rounded,
                    label: strings.history,
                  ),
                ),
                PopupMenuItem(
                  value: _HomeMenuAction.shop,
                  child: _MenuItem(
                    icon: Icons.storefront_rounded,
                    label: '${strings.shop}  $_coins ${strings.coins}',
                  ),
                ),
                if (_player?.hasPet ?? false)
                  PopupMenuItem(
                    value: _HomeMenuAction.pet,
                    child: _MenuItem(
                      icon: Icons.pets_rounded,
                      label: strings.pet,
                    ),
                  ),
                PopupMenuItem(
                  value: _HomeMenuAction.customize,
                  child: _MenuItem(
                    icon: Icons.palette_rounded,
                    label: strings.customize,
                  ),
                ),
              ],
              PopupMenuItem(
                value: _HomeMenuAction.settings,
                child: _MenuItem(
                  icon: Icons.settings_rounded,
                  label: strings.settings,
                ),
              ),
              PopupMenuItem(
                value: _HomeMenuAction.docs,
                child: _MenuItem(
                  icon: Icons.menu_book_rounded,
                  label: strings.documentation,
                ),
              ),
              PopupMenuItem(
                value: _HomeMenuAction.privacyPolicy,
                child: _MenuItem(
                  icon: Icons.privacy_tip_rounded,
                  label: strings.privacyPolicy,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Image.asset(
                  'assets/icons/math_master_icon.png',
                  width: 82,
                  height: 82,
                ),
              ),
              const SizedBox(height: 24),
              _SectionCard(
                title: strings.player,
                child: _loadingPlayer
                    ? const Center(child: CircularProgressIndicator())
                    : _buildPlayerSection(strings),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: strings.challengeLength,
                child: Wrap(
                  spacing: 10,
                  children: ChallengeDuration.values.map((d) {
                    final selected = d == _duration;
                    return ChoiceChip(
                      label: Text(strings.durationLabel(d)),
                      selected: selected,
                      onSelected: (_) => setState(() => _duration = d),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: strings.operationsToPractise,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: OperationType.values.map((op) {
                    final selected = _operations.contains(op);
                    return FilterChip(
                      label: Text('${op.symbol}  ${strings.operationLabel(op)}'),
                      selected: selected,
                      onSelected: (_) => _toggleOperation(op),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text(strings.start),
              ),
              if (_player?.hasPet ?? false) ...[
                const SizedBox(height: 16),
                PetCareCard(player: _player!, onTap: _openPetCare),
              ],
              const SizedBox(height: 20),
              const _ScoringHelp(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSection(AppStrings strings) {
    final player = _player;
    if (player == null) {
      return ElevatedButton.icon(
        onPressed: _choosePlayer,
        icon: const Icon(Icons.person_rounded),
        label: Text(strings.choosePlayer),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.person_rounded, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                player.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _choosePlayer,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(strings.changePlayer),
            ),
          ],
        ),
      ],
    );
  }
}

enum _HomeMenuAction {
  leaderboard,
  history,
  shop,
  pet,
  customize,
  settings,
  docs,
  privacyPolicy,
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary),
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ScoringHelp extends StatelessWidget {
  const _ScoringHelp();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.howScoringWorks,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(strings.scoreFast),
          Text(strings.scoreMedium),
          Text(strings.scoreSlow),
          Text(strings.scoreRepeat),
        ],
      ),
    );
  }
}
