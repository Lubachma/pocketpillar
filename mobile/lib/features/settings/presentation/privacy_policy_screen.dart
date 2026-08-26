import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';

/// Privacy policy — parity with iOS's `PrivacyPolicyView`: static
/// content in 7 sections (`privacy*` keys already migrated).
///
/// ⚠️ The wording of some keys (data "on the device", iOS Keychain,
/// anti-capture) no longer reflects the Flutter + backend
/// architecture — list logged in journal 3.10 for the user's
/// review; the keys are displayed as-is.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sections = <(String, String)>[
      (l10n.privacySectionDataCollected, l10n.privacyBodyDataCollected),
      (l10n.privacySectionPurpose, l10n.privacyBodyPurpose),
      (l10n.privacySectionStorage, l10n.privacyBodyStorage),
      (l10n.privacySectionSharing, l10n.privacyBodySharing),
      (l10n.privacySectionRights, l10n.privacyBodyRights),
      (l10n.privacySectionSecurity, l10n.privacyBodySecurity),
      (l10n.privacySectionContact, l10n.privacyBodyContact),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (title, body) in sections) ...[
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
