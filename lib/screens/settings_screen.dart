import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/pet.dart';
import '../models/player_profile.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../services/player_service.dart';
import '../services/theme_service.dart';
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
  ThemeMode _themeMode = ThemeMode.system;
  NotificationWindow _notificationWindow = NotificationService.defaultWindow;
  bool _notificationsAllowed = false;
  PlayerProfile? _player;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AudioService.loadSettings();
    final themeMode = await ThemeService.loadThemeMode();
    final notificationWindow = await NotificationService().loadWindow();
    final notificationsAllowed =
        await NotificationService().notificationsAllowed();
    final player = await _playerService.loadCurrent();
    if (!mounted) return;
    setState(() {
      _muted = settings.muted;
      _volume = settings.volume;
      _themeMode = themeMode;
      _notificationWindow = notificationWindow;
      _notificationsAllowed = notificationsAllowed;
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

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final app = context.findAncestorStateOfType<MathGameAppState>();
    if (app != null) {
      await app.setThemeMode(mode);
    } else {
      await ThemeService.saveThemeMode(mode);
    }
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
    await NotificationService().scheduleForPlayer(updated);
  }

  Future<void> _requestNotifications() async {
    final allowed = await NotificationService().requestPermissions();
    if (!mounted) return;
    setState(() => _notificationsAllowed = allowed);
  }

  Future<void> _setNotificationStart(int hour) async {
    final window = _notificationWindow.copyWith(startHour: hour);
    setState(() => _notificationWindow = window);
    await NotificationService().saveWindow(window);
  }

  Future<void> _setNotificationEnd(int hour) async {
    final window = _notificationWindow.copyWith(endHour: hour);
    setState(() => _notificationWindow = window);
    await NotificationService().saveWindow(window);
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
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 32,
                                        child: Text(
                                          AppStrings.languageIcon(
                                            locale.languageCode,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppStrings.languageName(
                                          locale.languageCode,
                                        ),
                                      ),
                                    ],
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
                  _SettingsCard(
                    icon: Icons.notifications_rounded,
                    title: strings.notifications,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _notificationsAllowed
                              ? strings.notificationsAllowed
                              : strings.notificationsBlocked,
                        ),
                        const SizedBox(height: 12),
                        if (!_notificationsAllowed)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: _requestNotifications,
                              icon: const Icon(Icons.notifications_active),
                              label: Text(strings.enableNotifications),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          strings.notificationWindow,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _HourDropdown(
                                label: strings.notificationFrom,
                                value: _notificationWindow.startHour,
                                onChanged: _setNotificationStart,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _HourDropdown(
                                label: strings.notificationTo,
                                value: _notificationWindow.endHour,
                                onChanged: _setNotificationEnd,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    icon: Icons.brightness_6_rounded,
                    title: strings.theme,
                    child: Column(
                      children: [
                        _ThemeModeTile(
                          icon: Icons.devices_rounded,
                          label: strings.themeSystem,
                          selected: _themeMode == ThemeMode.system,
                          onTap: () => _setThemeMode(ThemeMode.system),
                        ),
                        _ThemeModeTile(
                          icon: Icons.light_mode_rounded,
                          label: strings.themeLight,
                          selected: _themeMode == ThemeMode.light,
                          onTap: () => _setThemeMode(ThemeMode.light),
                        ),
                        _ThemeModeTile(
                          icon: Icons.dark_mode_rounded,
                          label: strings.themeDark,
                          selected: _themeMode == ThemeMode.dark,
                          onTap: () => _setThemeMode(ThemeMode.dark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: selected ? colorScheme.primary : null),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}

class _HourDropdown extends StatelessWidget {
  const _HourDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: value,
          onChanged: (hour) {
            if (hour != null) onChanged(hour);
          },
          items: [
            for (var hour = 0; hour < 24; hour++)
              DropdownMenuItem<int>(
                value: hour,
                child: Text('${hour.toString().padLeft(2, '0')}:00'),
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
