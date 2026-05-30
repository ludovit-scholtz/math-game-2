import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/audio_service.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _muted = false;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AudioService.loadSettings();
    if (!mounted) return;
    setState(() {
      _muted = settings.muted;
      _volume = settings.volume;
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
