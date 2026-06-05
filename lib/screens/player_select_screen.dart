import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/pet.dart';
import '../models/player_profile.dart';
import '../services/notification_service.dart';
import '../services/player_service.dart';
import '../theme.dart';
import '../widgets/pet_widgets.dart';

/// Lets the user pick a player from those who played before (so they don't have
/// to retype a name when switching players) or create a new one. Each player
/// keeps their own language preference.
class PlayerSelectScreen extends StatefulWidget {
  const PlayerSelectScreen({super.key});

  @override
  State<PlayerSelectScreen> createState() => _PlayerSelectScreenState();
}

class _PlayerSelectScreenState extends State<PlayerSelectScreen> {
  final PlayerService _service = PlayerService();
  final TextEditingController _nameController = TextEditingController();

  List<PlayerProfile> _players = [];
  bool _loading = true;
  late String _newLanguage;
  PetType _newPet = PetType.cat;

  @override
  void initState() {
    super.initState();
    _newLanguage = 'en';
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final players = await _service.loadPlayers();
    if (!mounted) return;
    setState(() {
      _players = players;
      if (players.isNotEmpty) _newLanguage = players.first.languageCode;
      _loading = false;
    });
  }

  Future<void> _select(PlayerProfile profile) async {
    await _service.selectOrCreate(profile);
    await NotificationService().scheduleForCurrentPlayer();
    if (!mounted) return;
    MathGameApp.of(context).setLocale(Locale(profile.languageCode));
    Navigator.of(context).pop(profile);
  }

  Future<void> _addNew() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final profile =
        PlayerProfile(name: name, languageCode: _newLanguage).withPet(_newPet);
    await NotificationService().requestPermissionsIfNeeded();
    await _select(profile);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.choosePlayer),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_players.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        strings.noPlayersYet,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  else ...[
                    Text(
                      strings.tapToPlay,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final player in _players)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: player.petType == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: AppTheme.primary,
                                )
                              : Image.asset(
                                  player.petType!.asset(PetMood.happy),
                                  width: 42,
                                  height: 42,
                                ),
                          title: Text(
                            player.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle:
                              Text(AppStrings.languageName(player.languageCode)),
                          trailing: const Icon(Icons.play_arrow_rounded),
                          onTap: () => _select(player),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            strings.newPlayer,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: strings.enterYourName,
                            ),
                            onSubmitted: (_) => _addNew(),
                          ),
                          const SizedBox(height: 12),
                          _LanguageDropdown(
                            value: _newLanguage,
                            label: strings.language,
                            onChanged: (code) =>
                                setState(() => _newLanguage = code),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            strings.choosePet,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          PetPickerGrid(
                            selectedPet: _newPet,
                            onSelected: (pet) => setState(() => _newPet = pet),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _addNew,
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: Text(strings.addPlayer),
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

/// A dropdown listing every supported language by its native name.
class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final String value;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        prefixIcon: const Icon(Icons.language_rounded),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          onChanged: (code) {
            if (code != null) onChanged(code);
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
                        AppStrings.languageIcon(locale.languageCode),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(AppStrings.languageName(locale.languageCode)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
