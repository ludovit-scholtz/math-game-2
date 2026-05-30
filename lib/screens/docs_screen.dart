import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme.dart';

/// In-game documentation explaining the coins, shop, button customization and
/// record/fireworks features.
class DocsScreen extends StatelessWidget {
  const DocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final sections = <_DocSection>[
      _DocSection('🪙', strings.docCoinsTitle, strings.docCoinsBody),
      _DocSection('🛍️', strings.docShopTitle, strings.docShopBody),
      _DocSection('🎨', strings.docCustomizeTitle, strings.docCustomizeBody),
      _DocSection('🎆', strings.docRecordsTitle, strings.docRecordsBody),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.documentation),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final section in sections)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(section.emoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              section.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        section.body,
                        style: Theme.of(context).textTheme.bodyMedium,
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

class _DocSection {
  const _DocSection(this.emoji, this.title, this.body);

  final String emoji;
  final String title;
  final String body;
}
