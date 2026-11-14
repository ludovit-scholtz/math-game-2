import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/operation_type.dart';
import '../models/practice_settings.dart';
import '../models/game_config.dart';

/// The form a parent uses to choose what a child practises. Shared by the
/// first-run setup and the parental control panel. It is stateless: every
/// change calls [onChanged] with the new settings.
class PracticeSettingsForm extends StatelessWidget {
  const PracticeSettingsForm({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final PracticeSettings settings;
  final ValueChanged<PracticeSettings> onChanged;

  void _toggleOperation(BuildContext context, OperationType op) {
    final ops = {...settings.operations};
    if (ops.contains(op)) {
      if (ops.length == 1 && settings.drills.isEmpty) {
        _keepOne(context);
        return;
      }
      ops.remove(op);
    } else {
      ops.add(op);
    }
    onChanged(settings.copyWith(operations: ops));
  }

  void _toggleDrill(BuildContext context, Drill drill) {
    final drills = {...settings.drills};
    if (drills.contains(drill)) {
      if (drills.length == 1 && settings.operations.isEmpty) {
        _keepOne(context);
        return;
      }
      drills.remove(drill);
    } else {
      drills.add(drill);
    }
    onChanged(settings.copyWith(drills: drills));
  }

  void _toggleTable(BuildContext context, int table) {
    final tables = {...settings.tables};
    if (tables.contains(table)) {
      if (tables.length == 1) {
        _keepOne(context);
        return;
      }
      tables.remove(table);
    } else {
      tables.add(table);
    }
    onChanged(settings.copyWith(tables: tables));
  }

  void _toggleDuration(BuildContext context, ChallengeDuration duration) {
    final durations = {...settings.durations};
    if (durations.contains(duration)) {
      if (durations.length == 1) {
        _keepOne(context);
        return;
      }
      durations.remove(duration);
    } else {
      durations.add(duration);
    }
    onChanged(settings.copyWith(durations: durations));
  }

  void _keepOne(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.strings.keepOneOptionOn)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: strings.quickSetup,
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final preset in PracticePreset.values)
                ChoiceChip(
                  key: ValueKey('preset-${preset.name}'),
                  label: Text(strings.presetLabel(preset)),
                  selected: settings.matchingPreset == preset,
                  onSelected: (_) =>
                      onChanged(PracticeSettings.preset(preset)),
                ),
            ],
          ),
        ),
        _Section(
          title: strings.operationsToPractise,
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final op in OperationType.values)
                FilterChip(
                  key: ValueKey('op-${op.storageKey}'),
                  label: Text('${op.symbol}  ${strings.operationLabel(op)}'),
                  selected: settings.operations.contains(op),
                  onSelected: (_) => _toggleOperation(context, op),
                ),
            ],
          ),
        ),
        _Section(
          title: strings.numberRange,
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final range in NumberRange.values)
                ChoiceChip(
                  key: ValueKey('range-${range.id}'),
                  label: Text(range.label),
                  selected: settings.range == range,
                  onSelected: (_) =>
                      onChanged(settings.copyWith(range: range)),
                ),
            ],
          ),
        ),
        _Section(
          title: strings.crossingTitle,
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final mode in CrossingMode.values)
                ChoiceChip(
                  key: ValueKey('crossing-${mode.id}'),
                  label: Text(strings.crossingLabel(mode)),
                  selected: settings.crossing == mode,
                  // Nothing within 5 reaches a ten.
                  onSelected: mode == CrossingMode.only &&
                          settings.range == NumberRange.within5
                      ? null
                      : (_) => onChanged(settings.copyWith(crossing: mode)),
                ),
            ],
          ),
        ),
        _Section(
          title: strings.drillsTitle,
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final drill in Drill.values)
                FilterChip(
                  key: ValueKey('drill-${drill.id}'),
                  label: Text('${strings.drillLabel(drill)} (${drill.example})'),
                  selected: settings.drills.contains(drill),
                  onSelected: (_) => _toggleDrill(context, drill),
                ),
            ],
          ),
        ),
        _Section(
          title: strings.tablesTitle,
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (var t = PracticeSettings.minTable;
                  t <= PracticeSettings.maxTable;
                  t++)
                FilterChip(
                  key: ValueKey('table-$t'),
                  label: Text('×$t'),
                  selected: settings.tables.contains(t),
                  onSelected: (_) => _toggleTable(context, t),
                ),
            ],
          ),
        ),
        _Section(
          title: strings.challengeLength,
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final duration in ChallengeDuration.values)
                FilterChip(
                  key: ValueKey('duration-${duration.index}'),
                  label: Text(strings.durationLabel(duration)),
                  selected: settings.durations.contains(duration),
                  onSelected: (_) => _toggleDuration(context, duration),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
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
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
