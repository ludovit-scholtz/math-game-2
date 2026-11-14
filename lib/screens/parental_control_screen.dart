import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/player_profile.dart';
import '../models/practice_settings.dart';
import '../services/parental_settings_service.dart';
import '../services/player_service.dart';
import '../theme.dart';
import '../widgets/practice_settings_form.dart';
import 'parental_history_screen.dart';

/// The parental control panel: what each player may practise, and the history
/// of every game played. Open it through the parental gate only.
class ParentalControlScreen extends StatefulWidget {
  const ParentalControlScreen({super.key, this.initialPlayerName});

  /// The player whose settings are shown first (usually the current player).
  final String? initialPlayerName;

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen> {
  final ParentalSettingsService _service = ParentalSettingsService();
  final PlayerService _playerService = PlayerService();

  List<PlayerProfile> _players = [];
  String? _playerName;
  PracticeSettings _settings = PracticeSettings.defaults();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final players = await _playerService.loadPlayers();
    String? name;
    if (players.isNotEmpty) {
      final wanted = widget.initialPlayerName;
      name = players.any((p) => p.name == wanted) ? wanted : players.first.name;
    }
    final settings = await _service.load(name);
    if (!mounted) return;
    setState(() {
      _players = players;
      _playerName = name;
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _selectPlayer(String name) async {
    final settings = await _service.load(name);
    if (!mounted) return;
    setState(() {
      _playerName = name;
      _settings = settings;
    });
  }

  Future<void> _changed(PracticeSettings settings) async {
    setState(() => _settings = settings);
    await _service.save(settings, _playerName);
  }

  Future<void> _applyToAll() async {
    await _service.saveForAll(_settings, _players.map((p) => p.name));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.strings.appliedToAll)));
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ParentalHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.parentalControl),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: ListTile(
                      key: const ValueKey('open-parental-history'),
                      leading: const Icon(Icons.history_rounded),
                      title: Text(strings.gameHistory),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _openHistory,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_players.isNotEmpty) ...[
                    Text(
                      strings.settingsFor,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      key: const ValueKey('parental-player'),
                      isExpanded: true,
                      value: _playerName,
                      items: [
                        for (final player in _players)
                          DropdownMenuItem(
                            value: player.name,
                            child: Text(player.name),
                          ),
                      ],
                      onChanged: (name) {
                        if (name != null) _selectPlayer(name);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  PracticeSettingsForm(
                    settings: _settings,
                    onChanged: _changed,
                  ),
                  if (_players.length > 1)
                    OutlinedButton.icon(
                      key: const ValueKey('apply-to-all'),
                      onPressed: _applyToAll,
                      icon: const Icon(Icons.groups_rounded),
                      label: Text(strings.applyToAll),
                    ),
                ],
              ),
      ),
    );
  }
}
