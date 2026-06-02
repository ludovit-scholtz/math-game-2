import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/pet.dart';
import '../models/player_profile.dart';
import '../services/audio_service.dart';
import '../services/player_service.dart';
import '../theme.dart';
import '../widgets/pet_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PlayerService _playerService = PlayerService();

  bool _loading = true;
  bool _muted = false;
  double _volume = 1.0;
  PlayerProfile? _player;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AudioService.loadSettings();
    final player = await _playerService.loadCurrent();
    if (!mounted) return;
    setState(() {
      _muted = settings.muted;
      _volume = settings.volume;
      _player = player;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    await AudioService.saveSettings(muted: _muted, volume: _volume);
  }

  Future<void> _toggleMuted() async {
    setState(() => _muted = !_muted);
    await _saveSettings();
  }

  Future<void> _setVolume(double value) async {
    setState(() => _volume = value);
    await _saveSettings();
  }

  Future<void> _changeLanguage(String code) async {
    final player = _player;
    if (player == null) return;
    final updated = await _playerService.setLanguage(player.name, code);
    if (!mounted || updated == null) return;
    setState(() => _player = updated);
    context.findAncestorStateOfType<MathGameAppState>()?.setLocale(Locale(code));
  }

  Future<void> _changePet(PetType pet) async {
    final player = _player;
    if (player == null) return;
    final updated = await _playerService.setPet(player.name, pet);
    if (!mounted || updated == null) return;
    setState(() => _player = updated);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.settings),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_player != null) ...[
                    _SettingsCard(
                      icon: Icons.language_rounded,
                      title: strings.language,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: strings.language,
                          prefixIcon: const Icon(Icons.language_rounded),
                          isDense: true,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _player!.languageCode,
                            onChanged: (code) {
                              if (code != null) _changeLanguage(code);
                            },
                            items: [
                              for (final locale in AppStrings.supportedLocales)
                                DropdownMenuItem<String>(
                                  value: locale.languageCode,
                                  child: Text(
                                    AppStrings.languageName(locale.languageCode),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsCard(
                      icon: Icons.pets_rounded,
                      title: strings.pet,
                      child: PetPickerGrid(
                        selectedPet: _player!.petType,
                        onSelected: _changePet,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.volume_up_rounded,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                strings.sound,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _toggleMuted,
                            icon: Icon(
                              _muted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                            ),
                            label: Text(
                              _muted ? strings.unmuteSound : strings.muteSound,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${strings.volume}: ${(_volume * 100).round()}%',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Slider(
                            value: _volume,
                            max: 1,
                            divisions: 20,
                            label: '${(_volume * 100).round()}%',
                            onChanged: (value) => _setVolume(value),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
