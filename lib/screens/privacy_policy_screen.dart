import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<String> _loadPolicy(BuildContext context) async {
    final code = Localizations.localeOf(context).languageCode;
    final localizedPath = code == 'en'
        ? 'docs/privacy-policy/index.md'
        : 'docs/privacy-policy/$code.md';
    try {
      return await rootBundle.loadString(localizedPath);
    } catch (_) {
      return rootBundle.loadString('docs/privacy-policy/index.md');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.privacyPolicy),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _loadPolicy(context),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: _MarkdownText(snapshot.data!),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MarkdownText extends StatelessWidget {
  const _MarkdownText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 10));
      } else if (line.startsWith('# ')) {
        widgets.add(
          Text(
            line.substring(2),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        );
      } else if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              line.substring(3),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•'),
                const SizedBox(width: 8),
                Expanded(child: Text(line.substring(2))),
              ],
            ),
          ),
        );
      } else {
        widgets.add(Text(line));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}