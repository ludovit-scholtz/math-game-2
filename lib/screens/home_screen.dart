import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/game_config.dart';
import '../models/operation_type.dart';
import '../models/player_profile.dart';
import '../models/practice_settings.dart';
import '../services/coin_service.dart';
import '../services/parental_settings_service.dart';
import '../services/player_service.dart';
import '../theme.dart';
import '../widgets/pet_widgets.dart';
import 'customization_screen.dart';
import 'docs_screen.dart';
import 'first_run_setup_screen.dart';
import 'game_screen.dart';
import 'history_screen.dart';
import 'parental_control_screen.dart';
import 'parental_gate_dialog.dart';
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
  final ParentalSettingsService _parentalService = ParentalSettingsService();

  PlayerProfile? _player;
  PracticeSettings _settings = PracticeSettings.defaults();
  bool _loadingPlayer = true;
  int _coins = 0;

  ChallengeDuration _duration = ChallengeDuration.oneMinute;
  final Set<OperationType> _operations = {
    OperationType.addition,
    OperationType.subtraction,
  };
  final Set<Drill> _drills = <Drill>{};

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Shows the first-run setup when needed, then loads the player.
  Future<void> _start() async {
    await _maybeShowSetup();
    if (!mounted) return;
    await _loadPlayer();
  }

  /// A parent chooses what the child practises the first time the app starts.
  /// Installations that already have players predate the setup and keep the
  /// classic behaviour, so they are not interrupted.
  Future<void> _maybeShowSetup() async {
    if (await _parentalService.isOnboarded()) return;
    final players = await _playerService.loadPlayers();
    if (players.isNotEmpty) {
      await _parentalService.markOnboarded();
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => const FirstRunSetupScreen(),
      ),
    );
  }

  /// Keeps the child's current choices where the parent still allows them.
  void _applySettings(PracticeSettings settings) {
    _settings = settings;
    if (!settings.durations.contains(_duration)) {
      _duration = ChallengeDuration.values
          .firstWhere(settings.durations.contains);
    }
    _operations.retainWhere(settings.operations.contains);
    _drills.retainWhere(settings.drills.contains);
    if (_operations.isEmpty && _drills.isEmpty) {
      final classic = settings.operations.intersection(
        {OperationType.addition, OperationType.subtraction},
      );
      if (classic.isNotEmpty) {
        _operations.addAll(classic);
      } else if (settings.operations.isNotEmpty) {
        _operations.add(settings.operations.first);
      } else {
        _drills.add(settings.drills.first);
      }
    }
  }

  Future<void> _loadSettings(String? playerName) async {
    final settings = await _parentalService.load(playerName);
    if (!mounted) return;
    setState(() => _applySettings(settings));
  }

  Future<void> _loadPlayer() async {
    final player = await _playerService.loadCurrent();
    // Player and restrictions are shown together, so Start never runs with
    // settings that are still loading.
    final settings = await _parentalService.load(player?.name);
    if (!mounted) return;
    setState(() {
      _player = player;
      _applySettings(settings);
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
      MathGameApp.of(context).setLocale(Locale(selected.languageCode));
      // Wait for this player's restrictions before a game can be started.
      await _loadSettings(selected.name);
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
        if (_operations.length + _drills.length > 1) _operations.remove(type);
      } else {
        _operations.add(type);
      }
    });
  }

  void _toggleDrill(Drill drill) {
    setState(() {
      if (_drills.contains(drill)) {
        if (_operations.length + _drills.length > 1) _drills.remove(drill);
      } else {
        _drills.add(drill);
      }
    });
  }

  Future<void> _openParentalControl() async {
    final passed = await showParentalGate(context);
    if (!passed || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ParentalControlScreen(
          initialPlayerName: _player?.name,
        ),
      ),
    );
    if (!mounted) return;
    await _loadSettings(_player?.name);
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
      drills: Set<Drill>.from(_drills),
      settings: _settings,
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
      case _HomeMenuAction.changePlayer:
        await _choosePlayer();
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
      case _HomeMenuAction.parental:
        await _openParentalControl();
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
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset('assets/icons/math_master_icon.png'),
        ),
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
                value: _HomeMenuAction.changePlayer,
                child: _MenuItem(
                  icon: Icons.swap_horiz_rounded,
                  label: strings.changePlayer,
                ),
              ),
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
                    label: '${strings.shop}  ${strings.coinCount(_coins)}',
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
                value: _HomeMenuAction.parental,
                child: _MenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: strings.parentalControl,
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
              if (_player?.hasPet ?? false) ...[
                PetCareCard(player: _player!, onTap: _openPetCare),
                const SizedBox(height: 16),
              ],
              _SectionCard(
                title: strings.challengeLength,
                child: Wrap(
                  spacing: 10,
                  children: ChallengeDuration.values
                      .where(_settings.durations.contains)
                      .map((d) {
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
                  children: OperationType.values
                      .where(_settings.operations.contains)
                      .map((op) {
                    final selected = _operations.contains(op);
                    return FilterChip(
                      label: Text('${op.symbol}  ${strings.operationLabel(op)}'),
                      selected: selected,
                      onSelected: (_) => _toggleOperation(op),
                    );
                  }).toList(),
                ),
              ),
              if (_settings.drills.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: strings.drillsTitle,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final drill in Drill.values)
                        if (_settings.drills.contains(drill))
                          FilterChip(
                            key: ValueKey('home-drill-${drill.id}'),
                            label: Text(
                              '${strings.drillLabel(drill)} (${drill.example})',
                            ),
                            selected: _drills.contains(drill),
                            onSelected: (_) => _toggleDrill(drill),
                          ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _PlayerGreeting(
                loading: _loadingPlayer,
                player: _player,
                onChoosePlayer: _choosePlayer,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text(strings.start),
              ),
              const SizedBox(height: 20),
              const _ScoringHelp(),
            ],
          ),
        ),
      ),
    );
  }

}

enum _HomeMenuAction {
  changePlayer,
  leaderboard,
  history,
  shop,
  pet,
  customize,
  settings,
  parental,
  docs,
  privacyPolicy,
}

class _PlayerGreeting extends StatelessWidget {
  const _PlayerGreeting({
    required this.loading,
    required this.player,
    required this.onChoosePlayer,
  });

  final bool loading;
  final PlayerProfile? player;
  final VoidCallback onChoosePlayer;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (player == null) {
      return OutlinedButton.icon(
        onPressed: onChoosePlayer,
        icon: const Icon(Icons.person_rounded),
        label: Text(strings.choosePlayer),
      );
    }
    return Text(
      strings.playerGreeting(player!.name),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
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
