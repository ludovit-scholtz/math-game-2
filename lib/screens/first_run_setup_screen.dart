import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/practice_settings.dart';
import '../services/parental_settings_service.dart';
import '../theme.dart';
import '../widgets/practice_settings_form.dart';

/// Shown once, the first time the app starts: a parent chooses what the child
/// will practise. The choice is saved as the template for every new player and
/// can be changed later in the parental control panel.
class FirstRunSetupScreen extends StatefulWidget {
  const FirstRunSetupScreen({super.key});

  @override
  State<FirstRunSetupScreen> createState() => _FirstRunSetupScreenState();
}

class _FirstRunSetupScreenState extends State<FirstRunSetupScreen> {
  final ParentalSettingsService _service = ParentalSettingsService();
  PracticeSettings _settings = PracticeSettings.defaults();
  bool _saving = false;

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    await _service.save(_settings);
    await _service.markOnboarded();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    // The setup is part of starting the app, so it cannot be dismissed.
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(strings.setupTitle),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      strings.setupMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 18),
                    PracticeSettingsForm(
                      settings: _settings,
                      onChanged: (value) => setState(() => _settings = value),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const ValueKey('setup-done'),
                    onPressed: _finish,
                    child: Text(strings.setupDone),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
